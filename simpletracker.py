#!/usr/bin/python
import sys
import os

def ping(address):
    return os.WEXITSTATUS(os.system("ping -c 1 -w 2 " + address + " > /dev/null 2>&1"))




# Main
address = sys.argv[1]
while true :
    response = ping(address)
    if response != 0 :
        print("Host unreachable : " + address)
        sys.exit(response)


