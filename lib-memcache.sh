#!/bin/bash

# Gist: 11375877
# Url: https://gist.github.com/goodevilgenius/11375877
#
# All memcache functions are supported.
#
# Can also be sourced from other scripts, e.g.
#    source membash.sh
#    MCSERVER="localhost"
#    MCPORT=11211
#    foobar=$(mc-get foobar)
#    [ -z "$foobar" ] && foobar="default value"
#    mc-set foobar 0 "$foobar"

# original author: wumin, https://gist.github.com/ri0day/1538831
# updated by goodevilgenius to support debian-based systems, support more
# functions, and be more user-friendly

MCSERVER="localhost"
MCPORT=11211

# Init Gitlab memecache, use it to set memecahe ip and port
# param 1: Memcache hostname, defaults to localhost
# param 2: Memecahe port, defaults to "11211"
function lib-memcache-init() {
	MCSERVER=${1:-"localhost"}
	MCPORT=${2:-11211}
}

mc-usage() {
	format_usage="membash: a memcache library for BASH \n\
https://gist.github.com/goodevilgenius/11375877\n\n\
Usage:\n
	\t $(basename "$0") [-hp] command [arguments] \n \
	\t [-h]\t memcached hostname or ip. \n \
	\t [-p]\t memcached port. \n\n\
Commands: \n \
	\t usage (print this help) \n \
	\t set/add/replace/append/prepend key exptime value \n \
	\t touch key exptime \n \
	\t incr/decr key value \n \
	\t get key \n \
	\t delete key [time] \n \
	\t stats \n \
	\t list-all-keys"
	echo -e $format_usage
}

mc-help() { mc-usage;}

mc-sendmsg() { echo -e "$*\r" | nc $MCSERVER $MCPORT | tr -d '\r';}

mc-stats() { mc-sendmsg "stats";}

mc-get-last-items-id() {
	local LastID=$(mc-sendmsg "stats items"|tail -n 2|head -n 1|awk -F':' '{print $2}')
	echo $LastID
}

mc-list-all-keys() {
	:>/dev/shm/mc-all-keys-${MCSERVER}-${MCPORT}.txt
	local max_item_num=$(mc-get-last-items-id)
	for i in `seq 1 $max_item_num`; do
		mc-sendmsg "stats cachedump $i 0" | awk '{print $2}'
	done >>/dev/shm/mc-all-keys-${MCSERVER}-${MCPORT}.txt
	sed -i '/^$/d' /dev/shm/mc-all-keys-${MCSERVER}-${MCPORT}.txt
	cat /dev/shm/mc-all-keys-${MCSERVER}-${MCPORT}.txt
}

mc-get() { mc-sendmsg "get $1" | awk "/^VALUE $1/{a=1;next}/^END/{a=0}a" ;}

mc-touch() {
	local key="$1"
	shift
	local exptime
	let exptime="$1"
	shift
	mc-sendmsg "touch $key $exptime"
}

mc-doset() {
	local command="$1"
	shift
	local key="$1"
	shift
	local exptime
	let exptime="$1"
	shift
	local val="$*"
	local bytes
	let bytes=$(echo -n "$val"|wc -c)
	mc-sendmsg "$command $key 0 $exptime $bytes\r\n$val"
}

mc-set() { mc-doset set "$@";}
mc-add() { mc-doset add "$@";}
mc-replace() { mc-doset replace "$@";}
mc-append() { mc-doset append "$@";}
mc-prepend() { mc-doset prepend "$@";}

mc-delete() { mc-sendmsg delete "$*";}
mc-incr() { mc-sendmsg incr "$*";}
mc-decr() { mc-sendmsg decr "$*";}

mc-superpurge() {
	mc-list-all-keys > /dev/null
	if [ ! -z "/dev/shm/mc-all-keys-${MCSERVER}-${MCPORT}.txt" ];then
		grep "$1" /dev/shm/mc-all-keys-${MCSERVER}-${MCPORT}.txt >/dev/shm/temp.swap.${MCSERVER}-${MCPORT}.txt
	fi
	while read keys; do
		mc-sendmsg "delete ${keys}"
	done </dev/shm/temp.swap.${MCSERVER}-${MCPORT}.txt

	rm -rf /dev/shm/temp.swap.${MCSERVER}-${MCPORT}.txt
}

if [ "$(basename "$0" .sh)" = "lib-memcache" ]; then

	MCSERVER="localhost"
	MCPORT=11211

	while getopts "h:p:" flag
	do
		case $flag in
			h)
				MCSERVER=${OPTARG:="localhost"}
				;;
			p)
				MCPORT=${OPTARG:="11211"}
				;;
			\?)
				echo "Invalid option: $OPTARG" >&2
				;;
		esac
	done
	command="${@:$OPTIND:1}"
	[ -z "$command" ] && command="usage"
	let OPTIND++

	mc-$command "${@:$OPTIND}"

	exit $?
fi
