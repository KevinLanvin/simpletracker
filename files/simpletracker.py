#!/usr/bin/python
import sys
import os
import time
import logging
from logging.handlers import RotatingFileHandler
from scapy.all import * 





##### ICMP Tracker

# Ping sends an ICMP message to <address> through the <interface> and awaits a response before <timeout> seconds.
# Returns the latency or -1 if no answer has been received before timeout occured.
def ping(address, iface, timeout = 2):
    packet = Ether()/IP(dst=address)/ICMP()
    try:
        ans,unans = srp(packet, timeout=timeout, iface=iface, filter='icmp', verbose=0)
    except socket.error:
        logger.error("Interface " + iface + " does not exist.")
        return -1
    if unans: 
        return 0
    t1 = ans[0][1].time
    t2 = ans[0][0].sent_time
    return (t1-t2)*1000


# track_ICMP starts tracking <address> using ping method. It calls the ping method every <interval> seconds with <adress> , <iface> and <timeout> as arguments
# Triggers an error when a ping fails
def track_ICMP(address, iface, timeout=2, interval=2):
    while 1 :
        response = ping(address, iface, timeout)
        if response <= 0 :
            logger.error("Host unreachable : " + address + "through interface " + iface)
        time.sleep(float(interval))






##### UDP Tracker (using DNS)
# send_dns_request sends a DNS query to its registered nameservers for the <domain> domain through the interface with <source> ip
# Returns a scapy dns response
def send_dns_request(domain, iface, timeout=2):
    # !!!!! TODO : change the hardcoded opendns address !!!!!
    try:
        ans,unans = srp(Ether()/IP(dst="208.67.222.222")/UDP()/DNS(rd=1,qd=DNSQR(qname=domain)),timeout=timeout, iface=iface, verbose=0)
    except socket.error:
        logger.error("Interface " + iface + " does not exist.")
        return -1
    if unans:
        logger.error("Cannot resolve domain " + domain + " on interface " + iface)
        return 0
    return ans


# get_public_IP uses send_dns_request to send a query for the domain "myip.opendns.com" through the interface with <source> ip. 
# It then extracts the ip address from the answer
# Returns a string containing the public ip.
def get_public_ip(iface):
        response = send_dns_request("myip.opendns.com",iface)
        return response[0][1][5].rdata






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
interface = sys.argv[2]
print(get_public_ip(interface))
print(ping(address,interface))
# Init DNS config
#dns_resolver = dns.resolver.Resolver()
#dns_resolver.nameservers = ['208.67.222.222','208.67.220.220']
# Main loop


