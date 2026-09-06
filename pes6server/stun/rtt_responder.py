#!/usr/bin/env python3
# -*- coding: utf-8 -*-
r"""PES6 对战链路 RTT 测量应答器 (UDP 5735)
客机一键启动【5/5】发 RTT-HELLO 到本机 5735 →
本器向该端点连发 20 个 RTT-PROBE(5 秒) → 客机原样回发 →
本器按回包计算每次 RTT 并记录到 stun\logtt_results.log
"""
import os, socket, time

PORT = 5735
LOGF = None

def out(msg):
    line = f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] {msg}"
    print(line, flush=True)
    if LOGF:
        try:
            LOGF.write(line + chr(10))
            LOGF.flush()
        except Exception:
            pass

def main():
    global LOGF
    log_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "log")
    os.makedirs(log_dir, exist_ok=True)
    LOGF = open(os.path.join(log_dir, "rtt_results.log"), "a", encoding="utf-8")
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind(("0.0.0.0", PORT))
    s.settimeout(0.5)
    out(f"RTT 应答器已启动 udp/{PORT}")
    pending = {}   # (ep, seq) -> 发出时刻
    rtts = {}      # ep -> [rtt 秒]
    probed = {}    # ep -> 上次探测时刻
    seq = 0
    while True:
        try:
            data, addr = s.recvfrom(2048)
        except socket.timeout:
            continue
        except OSError:
            continue
        ep = addr
        if data.startswith(b"RTT-HELLO"):
            last = probed.get(ep, 0)
            if time.time() - last > 60:
                probed[ep] = time.time()
                out(f"RTT 会话开始: {ep[0]}:{ep[1]}")
                def _probe(ep=ep):
                    for i in range(20):
                        time.sleep(0.25)
                        try:
                            pending[(ep, i)] = time.time()
                            s.sendto(b"RTT-PROBE " + str(i).encode(), ep)
                        except OSError:
                            pass
                threading.Thread(target=_probe, daemon=True).start()
        elif data.startswith(b"RTT-PROBE "):
            try:
                i = int(data.split()[1])
                t0 = pending.pop((ep, i), None)
                if t0 is not None:
                    rtt = (time.time() - t0) * 1000
                    rtts.setdefault(ep, []).append(rtt)
                    out(f"RTT {ep[0]}:{ep[1]} #{i}: {rtt:.1f}ms")
            except Exception:
                pass

import threading
main()
