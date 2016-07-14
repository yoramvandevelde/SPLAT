echo -en "  -> NTP output rules "
NTP_ENABLED=1
NTP4_ALLOW_HOSTS=( )
NTP6_ALLOW_HOSTS=( )

if [ $NTP_ENABLED -eq 1 ]; then
	echo "enabled."
	$PF4 -A OUTPUT -o $ETH -p udp --dport 123 -j ACCEPT
	$PF6 -A OUTPUT -o $ETH -p udp --dport 123 -j ACCEPT
else
	echo "disabled."
	if [ ! -z $NTP4_ALLOW_HOSTS ]; then
		COUNT=0
		while [ ${#HTTP4_ALLOW_HOSTS[*]} != $COUNT ]; do
			$PF4 -A OUTPUT -o $ETH -p udp --dport 123 -j ACCEPT
			COUNT=$((COUNT + 1))
		done
	fi
	
	if [ ! -z $NTP6_ALLOW_HOSTS ]; then
		COUNT=0
		while [ ${#HTTP6_ALLOW_HOSTS[*]} != $COUNT ]; do
			$PF6 -A OUTPUT -o $ETH -p udp --dport 123 -j ACCEPT
			COUNT=$((COUNT + 1))
		done
	fi
fi

