#!/usr/bin/python
import sys
import os
import socket
import time
import logging
from logging.handlers import RotatingFileHandler
import dns.resolver

##### ICMP Tracker

# Ping sends an ICMP message to <address> and awaits a response before <timeout> seconds.
# Returns the exit status of ping command.
def ping(address, timeout):
    return os.WEXITSTATUS(os.system("ping -c 1 -w " + timeout + " " + address + " > /dev/null 2>&1"))

# track_ICMP starts tracking <address> using ping method. It calls the ping method every <interval> seconds with <adress> and <timeout> as arguments
# Triggers an error when a ping fails
def track_ICMP(address, timeout="2", interval="2"):
    while 1 :
        response = ping(address, timeout)
        if response != 0 :
            logger.error("Host unreachable : " + address)
        time.sleep(float(interval))




##### UDP Tracker (using DNS)
# send_dns_request sends a DNS query to its registered nameservers for the <domain> domain through the interface with <source> ip
# Returns a dns.Answer object
def send_dns_request(domain,source):
    return dns_resolver.query(domain,source=source) 

# get_public_IP uses send_dns_request to send a query for the domain "myip.opendns.com" through the interface with <source> ip. 
# It then extracts the ip address from the answer
# Returns a string containing the public ip.
def get_public_IP(source):
        response = send_dns_request("myip.opendns.com",source)
        public_ip = response.response.answer[0].to_text().split(' ')[4]
        return public_ip

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
#address = sys.argv[1]
# Init DNS config
dns_resolver = dns.resolver.Resolver()
dns_resolver.nameservers = ['208.67.222.222','208.67.220.220']
# Main loop
answer = get_public_IP("147.135.134.1")
print(answer)
