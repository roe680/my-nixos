#!/usr/bin/env python3
"""
clangd-refresh-guard.py

Wraps clangd and sits between it and arduino-language-server.

arduino-language-server's LSP client (go.bug.st/lsp) panics when clangd
sends certain server->client requests it never implemented a handler for
(workspace/semanticTokens/refresh, workspace/inlayHint/refresh, etc.).

This proxy watches the stream coming FROM clangd, and for any request
whose method is in INTERCEPTED_METHODS, it immediately answers clangd
itself (result: null) and does NOT forward the request downstream to
arduino-language-server. Everything else passes through unchanged in
both directions.

Usage: point arduino-language-server's `-clangd` flag at this script
instead of the real clangd binary. Pass any extra clangd args straight
through, e.g.:

    arduino-language-server ... -clangd /path/to/clangd-refresh-guard.py -- -log=verbose ...

or simply rely on argv passthrough (see below).
"""

import json
import os
import subprocess
import sys
import threading

# Real clangd binary to launch. Override with CLANGD_REAL env var if needed.
CLANGD_BIN = os.environ.get("CLANGD_REAL", "clangd")

# Server->client requests known to crash arduino-language-server's LSP
# client if forwarded. We ack them locally with a null result instead.
INTERCEPTED_METHODS = {
    "workspace/semanticTokens/refresh",
    "workspace/inlayHint/refresh",
    "workspace/codeLens/refresh",
    "workspace/diagnostic/refresh",
    "workspace/foldingRange/refresh",
}


def read_message(stream):
    """Read one LSP frame (Content-Length header + JSON body) from a
    binary stream. Returns the raw bytes of the JSON body, or None on EOF."""
    headers = {}
    while True:
        line = stream.readline()
        if line in (b"", b"\r\n", b"\n"):
            if not headers:
                if line == b"":
                    return None
                continue
            break
        if line == b"":
            return None
        key, _, value = line.decode("ascii", "replace").partition(":")
        headers[key.strip().lower()] = value.strip()
    length = int(headers.get("content-length", "0"))
    body = stream.read(length)
    if len(body) < length:
        return None
    return body


def write_message(stream, raw_bytes, lock):
    header = f"Content-Length: {len(raw_bytes)}\r\n\r\n".encode("ascii")
    with lock:
        stream.write(header)
        stream.write(raw_bytes)
        stream.flush()


def pump_stdin_to_clangd(clangd_stdin, write_lock):
    """Forward everything from our stdin (arduino-language-server) to clangd's stdin, unchanged."""
    src = sys.stdin.buffer
    while True:
        body = read_message(src)
        if body is None:
            break
        write_message(clangd_stdin, body, write_lock)
    try:
        clangd_stdin.close()
    except Exception:
        pass


def pump_clangd_to_stdout(clangd_stdout, clangd_stdin, out_lock, in_lock):
    """Forward clangd's output to our stdout (arduino-language-server), except
    intercepted refresh requests, which we answer directly back to clangd."""
    dst = sys.stdout.buffer
    while True:
        body = read_message(clangd_stdout)
        if body is None:
            break

        forward = True
        try:
            msg = json.loads(body)
        except json.JSONDecodeError:
            msg = None

        if isinstance(msg, dict) and "method" in msg and "id" in msg:
            method = msg.get("method")
            if method in INTERCEPTED_METHODS:
                forward = False
                reply = json.dumps(
                    {"jsonrpc": "2.0", "id": msg["id"], "result": None}
                ).encode("utf-8")
                write_message(clangd_stdin, reply, in_lock)
                print(
                    f"[clangd-refresh-guard] intercepted {method} (id={msg['id']}), acked locally",
                    file=sys.stderr,
                )

        if forward:
            write_message(dst, body, out_lock)


def main():
    args = sys.argv[1:]
    proc = subprocess.Popen(
        [CLANGD_BIN, *args],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=sys.stderr,
    )

    out_lock = threading.Lock()  # guards our stdout (to arduino-language-server)
    in_lock = threading.Lock()   # guards clangd's stdin

    t1 = threading.Thread(
        target=pump_stdin_to_clangd, args=(proc.stdin, in_lock), daemon=True
    )
    t2 = threading.Thread(
        target=pump_clangd_to_stdout,
        args=(proc.stdout, proc.stdin, out_lock, in_lock),
        daemon=True,
    )
    t1.start()
    t2.start()

    proc.wait()
    sys.exit(proc.returncode)


if __name__ == "__main__":
    main()
