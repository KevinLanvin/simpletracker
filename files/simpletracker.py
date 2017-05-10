#!/usr/bin/python
import sys
import os
import socket

def ping(address):
    return os.WEXITSTATUS(os.system("ping -c 1 -w 2 " + address + " > /dev/null 2>&1"))


def set_keepalive(sock, after_idle_sec=1, interval_sec=3, max_fails=5):
    """Set TCP keepalive on an open socket.

    It activates after 1 second (after_idle_sec) of idleness,
    then sends a keepalive ping once every 3 seconds (interval_sec),
    and closes the connection after 5 failed ping (max_fails), or 15 seconds
    """
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_KEEPALIVE, 1)
    sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_KEEPIDLE, after_idle_sec)
    sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_KEEPINTVL, interval_sec)
    sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_KEEPCNT, max_fails)

# Main
"""
address = sys.argv[1]
while true :
    response = ping(address)
    if response != 0 :
        print("Host unreachable : " + address)
        sys.exit(response)

"""
print("hello")
