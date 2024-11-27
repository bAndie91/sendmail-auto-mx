#!/bin/bash

# This is a script to mimic sendmail(1) interface, but
# forward mail to local MTA via sendEmail(1).

. /usr/lib/tool/bash-utils || exit -1

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
	maildomain=`cat /etc/maildomain 2>/dev/null || domainname`
	if [ "$maildomain" = '(none)' ]; then maildomain=''; fi
	if [ -n "$maildomain" ]; then maildomain=localhost; fi
	envelope_sender=$USER@$maildomain
fi

if [ $get_recipients_from_headers = yes ]
then
	raw_email=`cat`
	recipient+=(`mail-extract-raw-headers -n To Cc Bcc <<< "$raw_email" | mime-header-decode | mail-extract-addresses | sort -u`)
fi

sendEmail -f "$envelope_sender" -t "${recipient[@]}" -o message-format=raw -o message-file=/dev/stdin -s "${SMTP_SERVER:-AUTO}" <<< "$raw_email"
