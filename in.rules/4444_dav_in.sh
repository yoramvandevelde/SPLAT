echo -en "  -> WEBDAV(S) input rules "
WEBDAV_ENABLED=0
WEBDAV4_ALLOW_HOSTS=( 192.168.1.24 10.0.1.0/24 )
WEBDAV6_ALLOW_HOSTS=( )
if [ "$WEBDAV_ENABLED" -eq 1 ]; then
	echo "enabled."
	# WEBDAV
	$PF4 -A INPUT -p tcp -m state --state NEW -m tcp --dport 4443:4446 -j ACCEPT
	$PF6 -A INPUT -p tcp -m state --state NEW -m tcp --dport 4443:4446 -j ACCEPT
else
	echo -en "publicly disabled.\n      Enabling for: ${WEBDAV4_ALLOW_HOSTS[*]}\n" 
	if [ ! ${#WEBDAV4_ALLOW_HOSTS[*]} -eq 1 ]; then
		COUNT=0
		while [ ${#WEBDAV4_ALLOW_HOSTS[*]} != $COUNT ]; do
			$PF4 -A INPUT -p tcp -m state --state NEW -m tcp --dport 4443:4446 -s ${WEBDAV4_ALLOW_HOSTS[$COUNT]} -j ACCEPT
			COUNT=$((COUNT + 1))
		done
	fi
	
	if [ ! ${#WEBDAV6_ALLOW_HOSTS[*]} -eq 1 ]; then
		COUNT=0
		while [ ${#WEBDAV6_ALLOW_HOSTS[*]} != $COUNT ]; do
			$PF6 -A INPUT -p tcp -m state --state NEW -m tcp --dport 4443:4446 -s ${WEBDAV6_ALLOW_HOSTS[$COUNT]} -j ACCEPT
			COUNT=$((COUNT + 1))
		done
	fi
fi
