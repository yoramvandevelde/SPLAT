#!/bin/bash -p 

#            ^ -p for sanitized env, no inheritance
#
# Lets start with an environment where the entire script
# fails on error. This is to limit unexpected behaviour.
# The pipefail is to make the entire line fail on piped
# programs.
set -euf -o pipefail
#source lib/lib_trap.sh

#we r00t?
if [ ! ${EUID} -eq 0 ]; then
	echo "No r00t, no w00t!";
	exit -1;
fi

## Probing the ipt/nf kernel modules when needed
#modprobe module_name

ETH="wlp0s26u1u4i2"
PF4="$(which iptables)"
PF6="$(which ip6tables)"
IPSET="$(which ipset) -!"
DATE="$(which date)"

echo -e "\e[31m\n   ██████  ██▓███   ██▓    ▄▄▄     ▄▄▄█████▓  "
echo " ▒██    ▒ ▓██░  ██▒▓██▒   ▒████▄   ▓  ██▒ ▓▒"
echo " ░ ▓██▄   ▓██░ ██▓▒▒██░   ▒██  ▀█▄ ▒ ▓██░ ▒░"
echo "   ▒   ██▒▒██▄█▓▒ ▒▒██░   ░██▄▄▄▄██░ ▓██▓ ░ "
echo " ▒██████▒▒▒██▒ ░  ░░██████▒▓█   ▓██▒ ▒██▒ ░ "
echo " ▒ ▒▓▒ ▒ ░▒▓▒░ ░  ░░ ▒░▓  ░▒▒   ▓▒█░ ▒ ░░   "
echo " ░ ░▒  ░ ░░▒ ░     ░ ░ ▒  ░ ▒   ▒▒ ░   ░    "
echo " ░  ░  ░  ░░         ░ ░    ░   ▒    ░      "
echo "       ░               ░  ░     ░  ░        "
echo -e "\e[0m\n\tSPugium Learning Attack Terminator\n\n"

##########################################################################################################

# A packetfilter rule is like a trapdoor. It stores the packet, checks if it 
# complies and then sends it through to the next rule. The sooner we apply a 
# DROP, REJECT or ACCEPT the sooner the handling of the packet is done. In 
# case of an ACCEPT this means the packet is at it's destination sooner if
# we do this right. 

## Let's flush the ruleset
echo -n "Flushing existing firewall rules..."
$PF4 -F
$PF4 -X
$PF6 -F
$PF6 -X
echo -e " \e[32mdone\e[0m"

echo -en "Enabling default INPUT DROP policy..."
$PF4 -P INPUT DROP
$PF6 -P INPUT DROP
echo -e " \e[32mdone\e[0m"
echo -en "Enabling default OUTPUT DROP policy..."
$PF4 -P OUTPUT DROP
$PF6 -P OUTPUT DROP
echo -e " \e[32mdone\e[0m"

##########################################################################################################

# First we drop all fucked up traffic

echo -e "Creating empty Fail2Ban ipsets for: \n  -> ssh_ddos, "
$IPSET create f2b_ssh_ddos hash:ip
echo  "  -> ssh_auth, "
$IPSET create f2b_ssh_auth hash:ip
echo  -n "  -> www_attacks... "
$IPSET create f2b_www_attack hash:ip
echo -e " \e[32mdone\e[0m"
echo -en "\nEnabling fail2ban DROP rules... "
$PF4 -A INPUT -p tcp -m set --match-set f2b_ssh_ddos src -j DROP
$PF4 -A INPUT -p tcp -m set --match-set f2b_ssh_auth src -j DROP
$PF4 -A INPUT -p tcp -m set --match-set f2b_www_attack src -j DROP
echo -e " \e[32mdone\e[0m\n"

##########################################################################################################

echo -en "Enabling REL/EST rules..."
$PF4 -A INPUT -p icmp -m icmp --icmp-type 8 -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT
$PF4 -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
$PF4 -A OUTPUT -p icmp -m icmp --icmp-type 8 -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT
$PF4 -A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
echo -e " \e[32mdone\e[0m"

echo -en "Adding INVALID state DROP rules... "
# creating chain
$PF4 -N drop_bad_packets
$PF6 -N drop_bad_packets

# check if state of syn is NEW otherwise DROP
$PF4 -A drop_bad_packets -p tcp ! --syn -m state --state NEW -j DROP
$PF6 -A drop_bad_packets -p tcp ! --syn -m state --state NEW -j DROP

# check if state of packet is INVALID and if so DROP
$PF4 -A drop_bad_packets -m state --state INVALID -j DROP
$PF6 -A drop_bad_packets -m state --state INVALID -j DROP
echo -e " \e[32mdone\e[0m"

##########################################################################################################

echo -n "Adding synflood chain... "
$PF4 -N synflood
$PF6 -N synflood
echo -en "\e[32mdone\e[0m\nAdding synflood chain ruleset... "

# send syn packets to synflood chain
$PF4 -A INPUT -p tcp --syn -j synflood
$PF6 -A INPUT -p tcp --syn -j synflood

# check if there is less than 1 syn per second with a burst of 3 and if so return
$PF4 -A synflood -p tcp --syn -m limit --limit 1/s --limit-burst 3 -j RETURN
$PF6 -A synflood -p tcp --syn -m limit --limit 1/s --limit-burst 3 -j RETURN

# ACCEPT RST's if they are not coming to fast 
$PF4 -A INPUT -p tcp -m tcp --tcp-flags RST RST -m limit --limit 2/second --limit-burst 2 -j ACCEPT
$PF6 -A INPUT -p tcp -m tcp --tcp-flags RST RST -m limit --limit 2/second --limit-burst 2 -j ACCEPT

# otherwise kill it with fire
$PF4 -A synflood -j DROP
$PF6 -A synflood -j DROP
echo -e " \e[32mdone\e[0m"

echo -en "Enabling syncookies... "
sysctl -w net.ipv4.tcp_syncookies=1 &> /dev/null
echo -e " \e[32mdone\e[0m\n"

##########################################################################################################

echo -en "Checking if blacklists are up to date... "
TIMESTR=$($DATE --date="now" "+%s")

SPLAT_RUN_DIR="/tmp"
BLACKLIST_TIMESTAMP_FILE="bl_timestamp"
UPDATE_BLACKLIST=0

# check blacklist_timestamp_file
if [ -e "$SPLAT_RUN_DIR/$BLACKLIST_TIMESTAMP_FILE" ]; then
	BLACKLIST_TIMESTAMP=$(cat $SPLAT_RUN_DIR/$BLACKLIST_TIMESTAMP_FILE)
	# if older than a week we will update
	if (($TIMESTR - $BLACKLIST_TIMESTAMP > "604800" )); then
		echo "Blacklists are updated more than a week ago."
		UPDATE_BLACKLIST=1
	fi
else
	if [ ! -e "$SPLAT_RUN_DIR" ]; then
		echo "ERROR: run dir ${SPLAT_RUN_DIR}	not found."
	fi

	echo $TIMESTR > $SPLAT_RUN_DIR/$BLACKLIST_TIMESTAMP_FILE;
	chmod 700 $SPLAT_RUN_DIR/$BLACKLIST_TIMESTAMP_FILE;
	UPDATE_BLACKLIST=1
fi
echo -e " \e[32mdone\e[0m\n"

if [ "$UPDATE_BLACKLIST" != 0 ]; then
	$IPSET -q flush
	echo -n "  We start with the bogons... "
	$IPSET create bl_bogons hash:net
	for bogon in $(/usr/bin/curl -s http://www.team-cymru.org/Services/Bogons/bogon-bn-agg.txt); 
		do $IPSET add bl_bogons $bogon; done
	echo -e " \e[32mdone\e[0m\n"
	echo -en "Enabling bl_bogons DROP rules... "
	$PF4 -A INPUT -m set --match-set bl_bogons src -j DROP
	echo -e " \e[32mdone\e[0m\n"
	
	#FIXME -> unblock for home connection
	ipset del bl_bogons 10.0.0.0/16

	echo -n "  Then we go for the CINS known offenders... "
	$IPSET create bl_ci_known hash:ip
	for ci_badguy in $(/usr/bin/curl -s http://cinsscore.com/list/ci-badguys.txt);
		do $IPSET add bl_ci_known $ci_badguy; done
	echo -e " \e[32mdone\e[0m\n"
	echo -en "  Enabling bl_ci_known DROP rules... "
	$PF4 -A INPUT -m set --match-set bl_ci_known src -j DROP
	echo -e " \e[32mdone\e[0m\n"

	echo -n "  Then shun the autoshun known offender list... "
	$IPSET create bl_shun hash:ip
	for shun in $(/usr/bin/curl -s http://www.autoshun.org/files/shunlist.csv| grep -v Shun| cut -d',' -f1); 
		do $IPSET add bl_shun $shun; done
	echo -e " \e[32mdone\e[0m\n"
	echo -en "  Enabling shun DROP rules... "
	$PF4 -A INPUT -m set --match-set bl_shun src -j DROP
	echo -e " \e[32mdone\e[0m\n"
fi

##########################################################################################################

echo -en "Creating ipset for admin users... "
$IPSET create sp_admins hash:ip,port
echo -e " \e[32mdone\e[0m\n"
$PF4 -A INPUT -m set --match-set sp_admins src -j ACCEPT
#$PF6 -A INPUT -m set --match-set sp_admins src -j ACCEPT

#########################################################################################################

echo "######"
echo "## SERVICES"
echo -en "#####\n  Loading service rules.. \n\n"

echo -e "  INBOUND"
for script in $(ls in.rules/); do
	source "in.rules/${script}";
done

echo -e "\n  OUTBOUND"
for script in $(ls out.rules/); do
	source "out.rules/${script}";
done

echo -e "\nDone. Go have some beer!\n\n"
