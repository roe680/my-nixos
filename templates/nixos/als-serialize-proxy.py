```python
#!/usr/bin/env python3
"""
als-serialize-proxy.py

ZedからのdidChange notificationsをそのままの内容(range付きincremental)で
中継するが、直前のdidChangeがまだ処理中(内部的な応答/次のdidOpenやリクエスト待ち)
の間は、次のdidChangeの送出を少し遅延させることで、ALS側の
「処理中に次のdidChangeが割り込んで内部状態が壊れる」レースを
外側から緩和するプロキシ。

変換は一切行わない。

また、ALS側で未実装のLSP requestについてはALSへ転送せず、
LSP上の正常な「結果なし(null)」を返すことで、ALSの
panic("unimplemented")によるプロセス終了を防ぐ。

ログも同時に記録する。
"""

import json
import subprocess
import sys
import threading
import time

LOG_PATH = "/tmp/als-proxy-raw.log"
DEBOUNCE_SECONDS = 0.03  # 30ms

# ALS側で未実装のためpanicすることが確認されているrequest。
#
# ここに追加したrequestはALSへ転送せず、
# {"jsonrpc":"2.0", "id": ..., "result": null}
# を返す。
#
# 通知(notification)ではなくrequestだけが対象。
UNIMPLEMENTED_REQUESTS = {
    "textDocument/onTypeFormatting",
}


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
    header = (
        "Content-Length: %d\r\n\r\n" % len(raw_obj_bytes)
    ).encode("ascii")

    stream.write(header + raw_obj_bytes)
    stream.flush()


def write_json_message(stream, obj):
    body = json.dumps(
        obj,
        separators=(",", ":"),
        ensure_ascii=False,
    ).encode("utf-8")

    write_message(stream, body)


def log(msg):
    with open(LOG_PATH, "a") as f:
        f.write("%.6f %s\n" % (time.time(), msg))


def ide_to_als_pump(instream, outstream):
    pending = [None]
    pending_lock = threading.Lock()
    flush_timer = [None]

    def flush_pending():
        with pending_lock:
            body = pending[0]

            if body is None:
                return

            pending[0] = None

            timer = flush_timer[0]
            flush_timer[0] = None

            if timer is not None:
                timer.cancel()

        log(
            "FLUSH didChange -> ALS: %s"
            % body.decode("utf-8", "replace")
        )

        write_message(outstream, body)

    def flush_timer_callback():
        flush_pending()

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

        # ------------------------------------------------------------
        # didChange
        # ------------------------------------------------------------
        if method == "textDocument/didChange":
            log(
                "RECV didChange: %s"
                % body.decode("utf-8", "replace")
            )

            with pending_lock:
                # 直前の未送信didChangeがあれば、
                # 古いものを破棄して最新だけ残す。
                pending[0] = body

                old_timer = flush_timer[0]

                if old_timer is not None:
                    old_timer.cancel()

                timer = threading.Timer(
                    DEBOUNCE_SECONDS,
                    flush_timer_callback,
                )

                flush_timer[0] = timer
                timer.start()

            continue

        # ------------------------------------------------------------
        # ALS未実装request
        # ------------------------------------------------------------
        #
        # LSP requestは "id" を持つ。
        # notificationには通常 "id" がないので、
        # requestの場合だけnull responseを返す。
        #
        if (
            method in UNIMPLEMENTED_REQUESTS
            and "id" in obj
        ):
            # didChangeより後に来たrequestなら、
            # 先に保留中のdidChangeをALSへ送る。
            flush_pending()

            request_id = obj["id"]

            log(
                "BLOCK unsupported request: method=%s id=%r"
                % (method, request_id)
            )

            response = {
                "jsonrpc": "2.0",
                "id": request_id,
                "result": None,
            }

            write_json_message(outstream, response)

            log(
                "RESP null: method=%s id=%r"
                % (method, request_id)
            )

            continue

        # ------------------------------------------------------------
        # その他のrequest / notification
        # ------------------------------------------------------------
        #
        # 直前にdidChangeが溜まっていれば、
        # それより先に送って順序を維持する。
        #
        flush_pending()

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
        print(
            "usage: als-serialize-proxy.py <real-binary> [args...]",
            file=sys.stderr,
        )
        sys.exit(1)

    proc = subprocess.Popen(
        [sys.argv[1], *sys.argv[2:]],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        bufsize=0,
    )

    t_in = threading.Thread(
        target=ide_to_als_pump,
        args=(sys.stdin.buffer, proc.stdin),
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
```
