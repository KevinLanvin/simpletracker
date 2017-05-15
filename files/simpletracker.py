#!/usr/bin/python
import sys
import os
import socket
import logger
from logging.handlers import RotatingFileHandler

def ping(address):
    return os.WEXITSTATUS(os.system("ping -c 1 -w 2 " + address + " > /dev/null 2>&1"))

def track_ICMP(address):
    while true :
        response = ping(address)
        if response != 0 :
            logger.error("Host unreachable : "+address)
            return

##### Main
### Init
# Init logger
logger = logging.getLogger()
logger.setLevel(logging.DEBUG)
formatter = logging.Formatter('%(asctime)s :: %(levelname)s :: %(message)s')
file_handler = RotatingFileHandler('activity.log', 'a', 1000000, 1)
file_handler.setLevel(logging.DEBUG)
file_handler.setFormatter(formatter)
logger.addHandler(file_handler)
# Init address
address = sys.argv[1]
# Main loop
track_ICMP(address)
