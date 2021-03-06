#!/bin/bash

# This is a script to mimic sendmail(1) interface, but
# forward mail to local MTA via sendEmail(1).

. /usr/lib/yazzy-utils/bash-utils || exit -1

maildomain()
{
	local c d
	for c in "cat /etc/mailname" domainname dnsdomainname
	do
		d=`command $c`
		if [ -n "$d" ]
		then
			echo "$d"
			return 0
		fi
	done
	return 1
}

declare -a recipient
from_header=''
envelope_sender=''
get_recipients_from_headers=no
single_dot_terminates_input=yes

while [ -n "$1" ]
do
	case "$1" in
	-F)	shift
		from_header=$1;;
	-f|-r)
		shift
		envelope_sender=$1;;
	-t)	get_recipients_from_headers=yes;;
	-ti)
		get_recipients_from_headers=yes
		single_dot_terminates_input=no
		;;
	-i|-oi)
		single_dot_terminates_input=no;;
	-o)
		shift
		warnx "Ignoring option: -o $1";;
	-bp|-bs)
		errx 22 "Option not supported: $1";;
	-*)	errx 22 "Unknown option: $1";;
	*)	recipient+=("$1");;
	esac
	shift
done

if [ $get_recipients_from_headers = yes -a ${#recipient[@]} != 0 ]
then
	errx 22 "Option -t and specifying recipients are mutually exclusive."
fi


if [ -z "$envelope_sender" ]
then
	envelope_sender=$USER@$(maildomain)
fi

if [ $get_recipients_from_headers = yes ]
then
	raw_email=`cat`
	# TODO
	recipient+=()
	echo "$raw_email" | sendEmail -f "$envelope_sender" -t "${recipient[@]}" -o message-format=raw -s AUTO
else
	sendEmail -f "$envelope_sender" -t "${recipient[@]}" -o message-format=raw -s AUTO
fi
