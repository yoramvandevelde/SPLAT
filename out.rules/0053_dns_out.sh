echo -en "  -> DNS output rules "
DNS_ENABLED=1
DNS4_ALLOW_HOSTS=( )
DNS6_ALLOW_HOSTS=( )

if [ $DNS_ENABLED -eq 1 ]; then
	echo "enabled."
	$PF4 -A OUTPUT -o $ETH -p udp -m state --state NEW --dport 53 -j ACCEPT
	$PF4 -A OUTPUT -o $ETH -p tcp -m state --state NEW --dport 53 -j ACCEPT
	$PF6 -A OUTPUT -o $ETH -p udp --dport 53 -j ACCEPT
	$PF6 -A OUTPUT -o $ETH -p tcp --dport 53 -j ACCEPT
else
	echo "disabled."
	if [ ! -z $DNS4_ALLOW_HOSTS ]; then
		COUNT=0
		while [ ${#DNS4_ALLOW_HOSTS[*]} != $COUNT ]; do
			$PF4 -A OUTPUT -o $ETH -p udp --dport 53 -j ACCEPT
			$PF4 -A OUTPUT -o $ETH -p tcp --dport 53 -j ACCEPT
			COUNT=$((COUNT + 1))
		done
	fi
	
	if [ ! -z $DNS6_ALLOW_HOSTS ]; then
		COUNT=0
		while [ ${#DNS6_ALLOW_HOSTS[*]} != $COUNT ]; do
			$PF6 -A OUTPUT -o $ETH -p udp --dport 53 -j ACCEPT
			$PF6 -A OUTPUT -o $ETH -p tcp --dport 53 -j ACCEPT
			COUNT=$((COUNT + 1))
		done
	fi
fi

