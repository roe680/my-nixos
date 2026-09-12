#!/usr/bin/env python3
"""
als-serialize-proxy.py

Zedからのdidacent notificationsをそのままの内容(range付きincremental)で
中継するが、直前のdidChangeがまだ処理中(内部的な応答/次のdidOpenやリクエスト待ち)
の間は、次のdidChangeの送出を少し遅延させることで、ALS側の
「処理中に次のdidChangeが割り込んで内部状態が壊れる」レースを
外側から緩和するプロキシ。

変換は一切行わない。ログも同時に記録する。
"""

import json
import subprocess
import sys
import threading
import time

LOG_PATH = "/tmp/als-proxy-raw.log"
DEBOUNCE_SECONDS = 0.03  # 30ms: この間隔より短い連続didChangeは1件にまとめて送る


def read_message(stream):
    headers = {}
    while True:
        line = stream.readline()
        if line == b"":
            return None
        line = line.rstrip(b"\r\n")
        if line == b"":
            break
        if b":" in line:
            k, v = line.split(b":", 1)
            headers[k.strip().lower()] = v.strip()
    length = int(headers.get(b"content-length", b"0"))
    body = b""
    while len(body) < length:
        chunk = stream.read(length - len(body))
        if not chunk:
            return None
        body += chunk
    return body


def write_message(stream, raw_obj_bytes):
    header = ("Content-Length: %d\r\n\r\n" % len(raw_obj_bytes)).encode("ascii")
    stream.write(header + raw_obj_bytes)
    stream.flush()


def log(msg):
    with open(LOG_PATH, "a") as f:
        f.write("%.6f %s\n" % (time.time(), msg))


def ide_to_als_pump(instream, outstream):
    pending = None
    pending_lock = threading.Lock()
    flush_timer = [None]

    def flush():
        with pending_lock:
            body = pending[0] if pending[0] else None
            pending[0] = None
        if body:
            log("FLUSH didChange -> ALS: %s" % body.decode("utf-8", "replace"))
            write_message(outstream, body)

    pending = [None]

    while True:
        body = read_message(instream)
        if body is None:
            break

        try:
            obj = json.loads(body)
        except Exception:
            write_message(outstream, body)
            continue

        method = obj.get("method")

        if method == "textDocument/didChange":
            log("RECV didChange: %s" % body.decode("utf-8", "replace"))
            with pending_lock:
                # 直前の未送信didChangeがあれば、それは古いので破棄して最新だけ残す
                pending[0] = body
            if flush_timer[0] is not None:
                flush_timer[0].cancel()
            t = threading.Timer(DEBOUNCE_SECONDS, flush)
            flush_timer[0] = t
            t.start()
        else:
            # didChange以外は素通し。ただし直前に溜まっているdidChangeが
            # あれば、それより先に送っておく(順序を壊さないため)
            with pending_lock:
                if pending[0] is not None:
                    if flush_timer[0] is not None:
                        flush_timer[0].cancel()
                    write_message(outstream, pending[0])
                    pending[0] = None
            write_message(outstream, body)


def raw_pump(src, dst):
    while True:
        chunk = src.read(4096)
        if not chunk:
            break
        dst.write(chunk)
        dst.flush()


def main():
    if len(sys.argv) < 2:
        print("usage: als-serialize-proxy.py <real-binary> [args...]", file=sys.stderr)
        sys.exit(1)

    proc = subprocess.Popen(
        [sys.argv[1], *sys.argv[2:]],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        bufsize=0,
    )

    t_in = threading.Thread(
        target=ide_to_als_pump, args=(sys.stdin.buffer, proc.stdin), daemon=True
    )
    t_out = threading.Thread(
        target=raw_pump, args=(proc.stdout, sys.stdout.buffer), daemon=True
    )
    t_in.start()
    t_out.start()
    proc.wait()


if __name__ == "__main__":
    main()
