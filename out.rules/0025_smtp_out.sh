echo -en "  -> SMTP output rules "
SMTP_ENABLED=1
SMTP_ALLOW_USERS=( root postfix )

if [ $SMTP_ENABLED -eq 1 ]; then
	echo "enabled."
	$PF4 -A OUTPUT -o $ETH -p tcp -m tcp -m state --state NEW -m multiport --dports 25,587 -j ACCEPT
	$PF6 -A OUTPUT -o $ETH -p tcp -m tcp -m state --state NEW -m multiport --dports 25,587 -j ACCEPT
else
	echo "disabled."
	if [ ! -z $SMTP_ALLOW_USERS ]; then
		COUNT=0
		while [ ${#SMTP_ALLOW_USERS[*]} != $COUNT ]; do
			#$PF4 -A OUTPUT -o $ETH -p tcp -m tcp --dport 25 -m owner --uid-owner ${SMTP_ALLOW_USERS[$COUNT]} -j ACCEPT 
			#$PF6 -A OUTPUT -o $ETH -p tcp -m tcp --dport 25 -m owner --uid-owner ${SMTP_ALLOW_USERS[$COUNT]} -j ACCEPT 
			COUNT=$((COUNT + 1))
		done
	fi
fi

