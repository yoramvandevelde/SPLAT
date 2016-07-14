echo -en "  -> HTTP(S) input rules "
HTTP_ENABLED=1
HTTP4_ALLOW_HOSTS=( )
HTTP6_ALLOW_HOSTS=( )
if [ "$HTTP_ENABLED" -eq 1 ]; then
	echo "enabled."
	# HTTP
	$PF4 -A OUTPUT -p tcp --syn --dport 80 -m connlimit --connlimit-above 15 --connlimit-mask 32 -j REJECT --reject-with tcp-reset
	$PF6 -A OUTPUT -p tcp --syn --dport 80 -m connlimit --connlimit-above 15 --connlimit-mask 32 -j REJECT --reject-with tcp-reset
	$PF4 -A OUTPUT -m state --state NEW -p tcp --dport 80 -j ACCEPT
	$PF6 -A OUTPUT -m state --state NEW -p tcp --dport 80 -j ACCEPT
	# HTTPS
	$PF4 -A OUTPUT -p tcp --syn --dport 443 -m connlimit --connlimit-above 15 --connlimit-mask 32 -j REJECT --reject-with tcp-reset
	$PF6 -A OUTPUT -p tcp --syn --dport 443 -m connlimit --connlimit-above 15 --connlimit-mask 32 -j REJECT --reject-with tcp-reset
	$PF4 -A OUTPUT -m state --state NEW -p tcp --dport 443 -j ACCEPT
	$PF6 -A OUTPUT -m state --state NEW -p tcp --dport 443 -j ACCEPT
	
else
	echo "disabled."
	if [ ! $HTTP4_ALLOW_HOSTS -eq 1 ]; then
		COUNT=0
		while [ ${#HTTP4_ALLOW_HOSTS[*]} != $COUNT ]; do
			$PF4 -A OUTPUT -m state --state NEW -p tcp --dport 80 -j ACCEPT
			$PF4 -A OUTPUT -m state --state NEW -p tcp --dport 443 -j ACCEPT
			COUNT=$((COUNT + 1))
		done
	fi
	
	if [ ! $HTTP6_ALLOW_HOSTS -eq 1 ]; then
		COUNT=0
		while [ ${#HTTP6_ALLOW_HOSTS[*]} != $COUNT ]; do
			$PF6 -A OUTPUT -m state --state NEW -p tcp --dport 80 -j ACCEPT
			$PF6 -A OUTPUT -m state --state NEW -p tcp --dport 443 -j ACCEPT
			COUNT=$((COUNT + 1))
		done
	fi
fi
