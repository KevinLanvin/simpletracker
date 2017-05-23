#!/bin/bash

name=$0
basename=$( basename "$0" )

usage() {
	printf "Usage : %s: [-m METHOD] [-t TIMEOUT] INTERFACE\n" "$name"
	exit 2
}

log() {
	logger -p user.notice -t "$basename" "$@"
}

. ./simpletracker.init
. ./simpletracker.requests

# Check arguments
while getopts "m:t:" opt; do
	case $opt in
		m) method="$OPTARG";;
		t) timeout="$OPTARG";;
		*) usage;;
	esac
done
shift $((OPTIND - 1))
[ -z "$1" ] && usage
	
# $1=<interface> , $2=<timeout>
# Calls check_ping_interface_for_destination until one destination answers. If no destinations answers, return Error code
_check_ping_interface() {
	if [ -z "$timeout" ];then
		timeout="${ping_timeout}"
	fi
	for destination in $ping_destinations; do
		local result=$( _check_ping_interface_for_destination "$1" "$destination" "$timeout")
		if [ "$result" == "$OK_CODE" ];then
			 echo "$OK_CODE"
			 return
		fi
	done
	log "Network unreachable on interface '$1' with ping method."
	echo "$ERROR_CODE"
}

# $1=<interface> $2=<destination> $3=<timeout>
# Returns OK or ERROR code depending on the result.
_check_ping_interface_for_destination() {
	local result=$( ping_request "$2" "$1" "$3" )
	if [ "$result" == "$ERROR_CODE" ]; then
		log "Ping $1 : Failure. Dst: $2. Timeout: $3"
		echo "$ERROR_CODE"
	else
		log "Ping $1 : $result ms."
		echo "$OK_CODE"
	fi
}



# $1=<interface>
_check_dns_interface() {
        if [ -z "$timeout" ]; then
                timeout="$dns_timeout"
        fi      
        for resolver in $dns_resolvers; do
                local result=$( _check_dns_interface_with_resolver "$1" "$resolver" "myip.opendns.com" "$timeout" )
                if [ "$result" == "$OK_CODE" ]; then
                        echo "$OK_CODE"
                        return
                fi      
        done    
        log "Network unreachable on interface '$1' with dns method."
        echo "$ERROR_CODE" 
}

# $1=<interface> , $2=<resolver> , $3=<domain> , $4=<timeout>
_check_dns_interface_with_resolver() {
        local result=$( dns_request "$1" "$2" "$3" "$4" )
	log "Result : $result"
        if [ "$result" == "$ERROR_CODE" ]; then
                log "DNS $1 : Failure. Resolver: $2. Domain: $3. Timeout: $4."
                echo "$ERROR_CODE"
        else    
		echo "Result : $result" 1>&2
                log "DNS '$1' : Latency: '$( echo "$result" | tail -n 1 )' ms. Public IP: '$( echo "$result" | head -n 1 )'."
                echo "$OK_CODE"
        fi      
}       



# $1=<interface>
# Dispatch between dns and ping method to check
check_interface() {
	if [ -z "$method" ];then
		if [ "$dns_enable" == "$ENABLED" ]; then
			method="dns"
		elif [ "$ping_enable" == "$ENABLED" ]; then
			method="ping"
		else
			log "No method selected to check '$1'"
			return -1	
		fi
	fi
	local result
	if [ "$method" == "dns" ];then
		result=$( _check_dns_interface "$1" )
	elif [ "$method" == "ping" ]; then
		result=$( _check_ping_interface "$1")
	else
		log "Method passed as argument is incorrect. Must be ping or dns."
		result="$ERROR_CODE"
	fi
	echo Interface "$1" : "$result"
}
init
check_interface "$1" 
