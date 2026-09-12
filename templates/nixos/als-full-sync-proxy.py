#!/usr/bin/env python3
"""
als-full-sync-proxy.py

Zed (や、その他incremental didChangeを送るLSPクライアント) と
arduino-language-server の間に立ち、textDocument/didChange を
Helixが送っているのと同じ「range無しのフルテキスト置き換え」に
変換してから下流(arduino-language-server-wrapped)へ転送するプロキシ。

Arduino Language Server 0.7.7 は initialize 応答で
TextDocumentSyncKind.Incremental を宣言しているが、
そのincremental差分の適用処理に nil pointer panic を起こす
バグがあるため、フルテキストだけを送るクライアント(Helix)では
問題が起きず、range付き差分を送る律儀なクライアント(Zed)でのみ
panicする。本プロキシは Zed 側の差分を全文に変換することで
このバグの経路を回避する。

Usage:
    als-full-sync-proxy.py <real-binary> [args...]

real-binary には arduino-language-server-wrapped
(またはarduino-language-server本体)へのパスを渡す。
"""

import json
import subprocess
import sys
import threading

# ---------------------------------------------------------------------------
# LSP message framing (Content-Length ヘッダ方式)
# ---------------------------------------------------------------------------

def read_message(stream):
    """Content-Lengthヘッダ付きの1メッセージを読み、bodyのbytesを返す。EOFならNone。"""
    headers = {}
    while True:
        line = stream.readline()
        if line == b"":
            return None  # EOF
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


def write_message(stream, obj):
    data = json.dumps(obj).encode("utf-8")
    header = ("Content-Length: %d\r\n\r\n" % len(data)).encode("ascii")
    stream.write(header + data)
    stream.flush()


# ---------------------------------------------------------------------------
# UTF-16位置 -> Python文字列オフセット変換
# (LSPのPosition.characterはUTF-16コードユニット単位)
# ---------------------------------------------------------------------------

def position_to_offset(text, line, character):
    lines = text.split("\n")
    offset = sum(len(l) + 1 for l in lines[:line])
    target_line = lines[line] if line < len(lines) else ""
    idx = 0
    count = 0
    for ch in target_line:
        if count >= character:
            break
        count += 2 if ord(ch) > 0xFFFF else 1
        idx += 1
    return offset + idx


def apply_change(text, change):
    if "range" not in change or change["range"] is None:
        # すでにフルテキスト置き換え
        return change["text"]
    start = change["range"]["start"]
    end = change["range"]["end"]
    start_off = position_to_offset(text, start["line"], start["character"])
    end_off = position_to_offset(text, end["line"], end["character"])
    return text[:start_off] + change["text"] + text[end_off:]


# ---------------------------------------------------------------------------
# didOpen / didChange / didClose のハンドリング
# ---------------------------------------------------------------------------

class DocStore:
    def __init__(self):
        self.docs = {}
        self.lock = threading.Lock()

    def on_did_open(self, params):
        uri = params["textDocument"]["uri"]
        with self.lock:
            self.docs[uri] = params["textDocument"]["text"]

    def on_did_close(self, params):
        uri = params["textDocument"]["uri"]
        with self.lock:
            self.docs.pop(uri, None)

    def on_did_change(self, params):
        uri = params["textDocument"]["uri"]
        with self.lock:
            text = self.docs.get(uri, "")
            had_range = False
            for change in params["contentChanges"]:
                if "range" in change and change["range"] is not None:
                    had_range = True
                text = apply_change(text, change)
            self.docs[uri] = text
            if had_range:
                # Helixと同じ形(range無し・全文)に書き換える
                params["contentChanges"] = [{"text": text}]
        return params


def ide_to_als_pump(instream, outstream, store):
    while True:
        body = read_message(instream)
        if body is None:
            break
        try:
            obj = json.loads(body)
        except Exception:
            # パース不能なら生のまま中継(安全側に倒す)
            outstream.write(
                ("Content-Length: %d\r\n\r\n" % len(body)).encode("ascii") + body
            )
            outstream.flush()
            continue

        method = obj.get("method")
        params = obj.get("params")

        if method == "textDocument/didOpen" and params:
            store.on_did_open(params)
        elif method == "textDocument/didChange" and params:
            obj["params"] = store.on_did_change(params)
        elif method == "textDocument/didClose" and params:
            store.on_did_close(params)

        write_message(outstream, obj)


def raw_pump(src, dst):
    while True:
        chunk = src.read(4096)
        if not chunk:
            break
        dst.write(chunk)
        dst.flush()


def main():
    if len(sys.argv) < 2:
        print("usage: als-full-sync-proxy.py <real-binary> [args...]", file=sys.stderr)
        sys.exit(1)

    real_bin = sys.argv[1]
    real_args = sys.argv[2:]

    proc = subprocess.Popen(
        [real_bin, *real_args],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        bufsize=0,
    )

    store = DocStore()

    t_in = threading.Thread(
        target=ide_to_als_pump,
        args=(sys.stdin.buffer, proc.stdin, store),
        daemon=True,
    )
    t_out = threading.Thread(
        target=raw_pump,
        args=(proc.stdout, sys.stdout.buffer),
        daemon=True,
    )
    t_in.start()
    t_out.start()

    proc.wait()


if __name__ == "__main__":
    main()
