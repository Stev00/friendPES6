#!/usr/bin/env python3
# -*- coding: utf-8 -*-
r"""
PES6 自建 STUN (老式 RFC3489 语义) + 对战 UDP 中继  v7
- 主 socket:  0.0.0.0:3478          (接收一切首次探测)
- 备 socket:  LAN_IP:3479 / 127.0.0.1:3479   (真实"第二IP:端口", 满足 CHANGE-REQUEST)
- Binding Response 携带 MAPPED-ADDRESS / SOURCE-ADDRESS / CHANGED-ADDRESS
- 通告地址按请求来源选择, 保证"通告 = 实际应答路径":
    127.x 来源   -> 通告 127.0.0.1 (本机回环测试)
    私网来源     -> 通告 LAN_IP
    其他(公网)   -> 通告 PUBLIC_IP (经 ikuai DNAT/SNAT 后客户端看到的就是它)
- CHANGE-REQUEST: 从备 socket(真换IP+换端口)应答;
  公网来源额外从主端口补发一份兜底应答(防端口受限 NAT 收不到)
- v6 移除旧版 UDP 5730-5740 echo
- v7 新增 --relay-port 对战中继: STUN 应答把 MAPPED-ADDRESS 通告为
  "公网IP:中继端口", 双方对战流汇聚到本进程中继线程, 转发互达——
  彻底绕开客户端侧 NAT 端口改写/过滤(如 
elease 类目录名、运营商光猫), 零配置联机
- 日志双通道: 控制台 + stun\log\stun_run.log
用法: python stun_server.py --public-ip 1.2.3.4 --lan-ip 192.168.50.113
"""
import argparse
import os
import socket
import struct
import sys
import threading
import time

ATTR_MAPPED = 0x0001
ATTR_CHANGE_REQ = 0x0003
ATTR_SOURCE = 0x0004
ATTR_CHANGED = 0x0005
ATTR_SOFTWARE = 0x8022

MSG_BINDING_REQ = 0x0001
MSG_BINDING_RESP = 0x0101

SOFTWARE = b'PES6-HOME-STUN'

LOGF = None


def out(msg):
    line = f'[{time.strftime("%Y-%m-%d %H:%M:%S")}] {msg}'
    print(line, flush=True)
    if LOGF is not None:
        try:
            LOGF.write(line + '\n')
            LOGF.flush()
        except Exception:
            pass


def is_loopback(ip: str) -> bool:
    return ip.startswith('127.') or ip == '0.0.0.0'


def is_private_lan(ip: str) -> bool:
    if ip.startswith('10.') or ip.startswith('192.168.'):
        return True
    if ip.startswith('172.'):
        try:
            return 16 <= int(ip.split('.')[1]) <= 31
        except Exception:
            return False
    return ip.startswith('169.254.')


def addr_attr(attr_type: int, ip: str, port: int) -> bytes:
    val = struct.pack('!BBH', 0, 1, port) + socket.inet_aton(ip)
    return struct.pack('!HH', attr_type, len(val)) + val


def parse_attrs(data: bytes):
    attrs = {}
    off = 20
    while off + 4 <= len(data):
        t, l = struct.unpack('!HH', data[off:off + 4])
        attrs[t] = data[off + 4:off + 4 + l]
        off += 4 + l
    return attrs


class StunServer:
    def __init__(self, lan_ip, pub_ip, base_port=3478, relay_port=0):
        self.lan_ip = lan_ip
        self.pub_ip = pub_ip
        self.base_port = base_port
        self.alt_port = base_port + 1
        self.relay_port = relay_port
        self.primary = None
        self.alt_loop = None
        self.alt_lan = None

    def advert_ip(self, peer_ip: str) -> str:
        if is_loopback(peer_ip):
            return '127.0.0.1'
        if is_private_lan(peer_ip):
            return self.lan_ip
        return self.pub_ip

    def pick_alt(self, peer_ip: str):
        """按来源挑备用 socket, 返回 (socket, 通告IP)"""
        if is_loopback(peer_ip) and self.alt_loop is not None:
            return self.alt_loop, '127.0.0.1'
        if self.alt_lan is not None:
            return self.alt_lan, (self.lan_ip if is_private_lan(peer_ip)
                                  else self.pub_ip)
        return None, self.lan_ip

    def handle_primary(self, data, addr):
        peer_ip, peer_port = addr[0], addr[1]
        if len(data) < 20:
            return
        mtype, _ = struct.unpack('!HH', data[:4])
        txid = data[4:20]
        if mtype != MSG_BINDING_REQ:
            self.primary.sendto(data, addr)
            out(f'ECHO {peer_ip}:{peer_port} {len(data)}B')
            return
        adv = self.advert_ip(peer_ip)
        alt_sock, _ = self.pick_alt(peer_ip)
        attrs = parse_attrs(data)
        creq = attrs.get(ATTR_CHANGE_REQ)
        want_change = bool(creq and len(creq) >= 4
                           and (struct.unpack('!I', creq[:4])[0] & 0x06))
        mapped = ((self.pub_ip, self.relay_port) if self.relay_port
                  else (peer_ip, peer_port))
        if want_change and alt_sock is not None:
            pkt = self._resp(txid, mapped,
                             (adv, self.alt_port), (adv, self.alt_port))
            try:
                alt_sock.sendto(pkt, addr)
            except OSError:
                self.primary.sendto(pkt, addr)
            out(f'STUN {peer_ip}:{peer_port} change-req -> alt {adv}:{self.alt_port}')
            if not is_loopback(peer_ip) and not is_private_lan(peer_ip):
                # 公网来源(端口受限 NAT 可能收不到 :3479 的回包):
                # 同时从主端口补发一份"未变更"应答兜底
                pkt2 = self._resp(txid, mapped,
                                  (adv, self.base_port), (adv, self.alt_port))
                try:
                    self.primary.sendto(pkt2, addr)
                    out(f'STUN {peer_ip}:{peer_port} change-req -> primary(fallback)')
                except OSError:
                    pass
        else:
            pkt = self._resp(txid, mapped,
                             (adv, self.base_port), (adv, self.alt_port))
            self.primary.sendto(pkt, addr)
            out(f'STUN {peer_ip}:{peer_port} -> primary {adv}:{self.base_port}')

    def handle_alt(self, sock, data, addr):
        # 客户端直接探测 3479 时: 用接收它的那个 socket 应答
        # 通告地址按"请求来源"判定, 保证与实际路径一致
        peer_ip, peer_port = addr[0], addr[1]
        if len(data) < 20:
            sock.sendto(data, addr)
            return
        mtype, _ = struct.unpack('!HH', data[:4])
        txid = data[4:20]
        if mtype != MSG_BINDING_REQ:
            sock.sendto(data, addr)
            return
        adv = self.advert_ip(peer_ip)
        mapped = ((self.pub_ip, self.relay_port) if self.relay_port
                  else (peer_ip, peer_port))
        pkt = self._resp(txid, mapped, (adv, self.alt_port),
                         (adv, self.alt_port))
        sock.sendto(pkt, addr)
        out(f'STUN {peer_ip}:{peer_port} (alt-direct) -> {adv}:{self.alt_port}')

    @staticmethod
    def _resp(txid, mapped, source, changed):
        attrs = (addr_attr(ATTR_MAPPED, *mapped)
                 + addr_attr(ATTR_SOURCE, *source)
                 + addr_attr(ATTR_CHANGED, *changed)
                 + struct.pack('!HH', ATTR_SOFTWARE, len(SOFTWARE)) + SOFTWARE)
        return struct.pack('!HH', MSG_BINDING_RESP, len(attrs)) + txid + attrs

    def run(self):
        global LOGF
        log_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'log')
        os.makedirs(log_dir, exist_ok=True)
        LOGF = open(os.path.join(log_dir, 'stun_run.log'), 'a', encoding='utf-8')

        self.primary = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.primary.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.primary.bind(('0.0.0.0', self.base_port))
        alts = [(self.lan_ip, 'alt_lan')]
        if not self.lan_ip.startswith('127.'):
            alts.insert(0, ('127.0.0.1', 'alt_loop'))
        for ip, attr_name in alts:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            try:
                s.bind((ip, self.alt_port))
                setattr(self, attr_name, s)
            except OSError as e:
                out(f'[警告] 备 socket {ip}:{self.alt_port} 绑定失败: {e}')
        if self.alt_lan is None and self.alt_loop is None:
            out('[致命] 没有任何备用 3479 socket 可用')
            sys.exit(1)

        bound_alts = []
        if self.alt_loop is not None:
            bound_alts.append(f'127.0.0.1:{self.alt_port}')
        if self.alt_lan is not None:
            bound_alts.append(f'{self.lan_ip}:{self.alt_port}')
        out(f'STUN primary=0.0.0.0:{self.base_port} alt={bound_alts} '
            f'LAN={self.lan_ip} PUB={self.pub_ip}')

        threads = [threading.Thread(target=self._loop,
                                    args=(self.primary, self.handle_primary),
                                    daemon=True)]
        for s, ip in ((self.alt_loop, '127.0.0.1'), (self.alt_lan, self.lan_ip)):
            if s is not None:
                threads.append(threading.Thread(
                    target=self._loop,
                    args=(s, lambda d, a, sk=s: self.handle_alt(sk, d, a)),
                    daemon=True))
        if self.relay_port:
            threads.append(threading.Thread(target=self._relay_loop,
                                            daemon=True))
            out(f'中继已启动: 0.0.0.0:{self.relay_port} (对战流互转模式)')
        for t in threads:
            t.start()
        try:
            while True:
                time.sleep(3600)
        except KeyboardInterrupt:
            pass

    def _loop(self, sock, handler):
        while True:
            try:
                data, addr = sock.recvfrom(2048)
                handler(data, addr)
            except Exception as e:
                out(f'[warn] {e}')
                time.sleep(0.2)

    def _relay_loop(self):
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.bind(('0.0.0.0', self.relay_port))
        s.settimeout(1.0)
        peers = {}
        recent = []          # (time, data, addr) 近期包缓冲, 供新端点补发
        while True:
            try:
                data, addr = s.recvfrom(65535)
            except socket.timeout:
                continue
            except OSError as e:
                out(f'[warn] relay {e}')
                continue
            now = time.time()
            known = [p for p, t in list(peers.items()) if now - t < 60]
            if addr not in known:
                out(f'中继: 新端点 {addr[0]}:{addr[1]} (当前 {len(known)+1} 个)')
                # 把最近 3 秒内的缓冲包补发给新端点(消除首包竞态)
                for bt, bdata, baddr in list(recent):
                    if now - bt <= 3 and baddr != addr:
                        try:
                            s.sendto(bdata, addr)
                        except OSError:
                            pass
            peers[addr] = now
            recent.append((now, data, addr))
            del recent[:-64]
            for p in known:
                if p != addr:
                    try:
                        s.sendto(data, p)
                    except OSError:
                        pass

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--public-ip', required=True)
    ap.add_argument('--lan-ip', default='192.168.50.113')
    ap.add_argument('--base-port', type=int, default=3478)
    ap.add_argument('--relay-port', type=int, default=0)
    a = ap.parse_args()
    StunServer(a.lan_ip, a.public_ip, a.base_port, a.relay_port).run()


if __name__ == '__main__':
    main()
