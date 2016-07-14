echo -en "  -> SSH output rules "
# Enable SSH 
SSH_ENABLED=1

SSH4_ALLOW_HOSTS=( )
SSH6_ALLOW_HOSTS=( )

if [ $SSH_ENABLED -eq 1 ]; then
	echo "enabled."
	# SSH
	$PF4 -A OUTPUT -o $ETH -m state --state NEW -p tcp --dport 22 -j ACCEPT
	$PF6 -A OUTPUT -o $ETH -m state --state NEW -p tcp --dport 22 -j ACCEPT
else
	echo "disabled."
fi
