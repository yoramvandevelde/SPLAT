echo -en "  -> SSH input rules "

# Enable SSH 
SSH_ENABLED=0

SSH4_ALLOW_HOSTS=( 10.0.1.0/24 )
SSH6_ALLOW_HOSTS=( )

if [ $SSH_ENABLED -eq 1 ]; then
	echo "enabled."
	# SSH
	$PF4 -A INPUT -p tcp --syn --dport 22 -m connlimit --connlimit-above 15 --connlimit-mask 32 -j REJECT --reject-with tcp-reset
	$PF6 -A INPUT -p tcp --syn --dport 22 -m connlimit --connlimit-above 15 --connlimit-mask 32 -j REJECT --reject-with tcp-reset
	$PF4 -A INPUT -i $ETH -m state --state NEW -p tcp --dport 22 -j ACCEPT
	$PF6 -A INPUT -i $ETH -m state --state NEW -p tcp --dport 22 -j ACCEPT
else
	echo "publicly disabled. Adding $SSH4_ALLOW_HOSTS and $SSH6_ALLOW_HOSTS."
	if [ ! -z $SSH4_ALLOW_HOSTS ]; then
		COUNT=0
		while [ ${#SSH4_ALLOW_HOSTS[*]} != $COUNT ]; do
			$PF4 -A INPUT -i $ETH -m state --state NEW -p tcp --dport 22 -j ACCEPT
			COUNT=$((COUNT + 1))
		done
	fi
	
	if [ ! -z $SSH6_ALLOW_HOSTS ]; then
		COUNT=0
		while [ ${#SSH6_ALLOW_HOSTS[*]} != $COUNT ]; do
			$PF6 -A INPUT -i $ETH -m state --state NEW -p tcp --dport 22 -j ACCEPT
			COUNT=$((COUNT + 1))
		done
	fi
fi
