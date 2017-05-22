#!/bin/bash


# Constants
readonly OK_CODE="0"
readonly ERROR_CODE="-1"
readonly ENABLED="1"




# UCI Macros
function UCI_GET {
	uci get simpletracker."$1"
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
	ping_destinations=$( UCI_GET_PING "destinations" )
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
	ip addr show "$1" | grep -w inet | awk '{print $2}' | cut -d / -f 1
}



# $1=<interface> , $2=<resolver_address> , $3=<domain> , $4=<timeout> 
function dns_request {
	local interface_ip=$( get_interface_ip "$1" )
	local response=$( dig -b "$interface_ip" "$3" @"$2" +time="$4" +noall +answer +stats )
	echo "$response" | grep -v ';' | cut -f 5
	echo "$response" | grep msec | cut -d ' ' -f 4
}

# $1=<interface>
function get_public_ip {
	dns_request "$1" "${dns_resolvers[0]}" "$dns_domain" "$dns_timeout"
}

# $1=<interface>
# Dispatch between dns and ping method to check
function check_interface {
	local result
	if [ "$dns_enable" == "$ENABLED" ]; then
		result=$( check_dns_interface "$1" )
	elif [ "$ping_enable" == "$ENABLED" ]; then
		result=$( check_ping_interface "$1")
	else
		echo "There is no method selected to check connectivity. Please set enable option to 1 in dns or ping section of configuration file" >> logs
		result="$ERROR_CODE"
	fi
	echo Interface "$1" : "$result"
}

# $1=<interface>
# Calls check_ping_interface_for_destination until one destination answers. If no destinations answers, return Error code
function check_ping_interface {
	for destination in $ping_destinations; do
		local result=$( check_ping_interface_for_destination "$1" "$destination" )
		if [ "$result" == "$OK_CODE" ];then
			 echo "$OK_CODE"
			 return
		fi
		done
		echo "Network unreachable on interface '$1' with ping method." >> logs
	echo "$ERROR_CODE"
}

# $1=<interface> $2=<destination> 
# Returns OK or ERROR code depending on the result.
function check_ping_interface_for_destination {
	local result=$( ping_request "$2" "$1" "$ping_timeout" )
	if [ "$result" == "$ERROR_CODE" ]; then
		echo "$ERROR_CODE"
	else
		echo Pinging on interface "$1" : "$result" ms  >> logs
		echo "$OK_CODE"
	fi
}

# $1=<address> , $2=<interface> , $3=<timeout> , $4=<result>
# Returns -1 if something wrong happened.
function ping_request {
	local response
	response=$( ping -c 1 -I "$2" -W "$3" "$1" )
	if [ $? -ne 0 ]; then
		echo "$ERROR_CODE"
	else 
		echo "$response" | cut -d '/' -s -f5
	fi
}



# Main 
init_uci_config
touch logs
r1="$( check_ping_interface if2 )"
r2="$( check_ping_interface if1 )"
echo Reponse 1 : "$r1" 
echo Reponse 2 : "$r2"
