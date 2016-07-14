#!/bin/bash -p


echo -n "Flushing existing firewall rules..."
iptables -F
iptables -X
ip6tables -F
ip6tables -X

echo -e " \e[32mdone\e[0m"
echo -n "SEtting default firewall policy to ACCEPT..."
	
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
ip6tables -P INPUT ACCEPT
ip6tables -P OUTPUT ACCEPT

echo -e " \e[32mdone\e[0m\n"

for i in $(seq 0 2); do
	echo -e "   -> \e[31mWATCH OUT! YOU ARE NOT PROTECTED AT THIS MOMENT!\e[0m";
	echo -e "   -> \e[31mNever leave at this state in production!\e[0m\n";
	sleep 1;
done

echo -e "\nIP4TABLES:"
iptables -L -n
echo -e "\nIP6TABLES:"
ip6tables -L -n

echo
