#!/bin/bash



# UCI Macros
function UCI_GET {
	command uci get simpletracker."$1"
}
function UCI_GET_PING {
	UCI_GET "ping.""$1"
}
function UCI_GET_DNS {
	UCI_GET "dns.""$1"
}


# Initialization
function init_uci_config {
	init_uci_config_ping
	init_uci_config_dns
}

function init_uci_config_ping {
	ping_interfaces=$( UCI_GET_PING "interfaces" )
	ping_destination=$( UCI_GET_PING "destination_ip" )
	ping_timeout=$( UCI_GET_PING "timeout" )
	ping_enable=$( UCI_GET_PING "enable" )
}

function init_uci_config_dns {
	dns_resolvers=$( UCI_GET_DNS "resolvers" )
	dns_timeout=$( UCI_GET_DNS "timeout" )
	dns_domain=$( UCI_GET_DNS "domain" )
	dns_interfaces=$( UCI_GET_DNS "interfaces" )
	dns_enable=$( UCI_GET_DNS "enable" )
}



#$1=<interface>
function get_interface_ip {
	command ip addr show "$1" | grep -w inet | awk '{print $2}' | cut -d / -f 1
}

# $1=<address> , $2=<interface> , $3=<timeout>
function ping {
	local toto=$( command ping -c 1 -I "$2" -W "$3" -s 24 "$1" )
	command echo "$toto" | cut -d '/' -s -f5
}

# $1=<interface> , $2=<resolver_address> , $3=<domain> , $4=<timeout> 
function dns_request {
	local interface_ip=$( get_interface_ip "$1" )
	response=$( command dig -b "$interface_ip" "$3" @"$2" +time="$4" +noall +answer +stats )
	echo "$response" | grep -v ';' | cut -f 5
	echo "$response" | grep msec | cut -d ' ' -f 4
}

# $1=<interface>
function get_public_ip {
	dns_request "$1" "${dns_resolvers[0]}" "$dns_domain" "$dns_timeout"
}



# Main 
init_uci_config
for iface in $ping_interfaces; do
	ping "$ping_destination" "$iface" "$ping_timeout"
done

for iface in $dns_interfaces; do
	get_public_ip "$iface"
done
