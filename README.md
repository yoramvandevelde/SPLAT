```

   ██████  ██▓███   ██▓    ▄▄▄     ▄▄▄█████▓  
 ▒██    ▒ ▓██░  ██▒▓██▒   ▒████▄   ▓  ██▒ ▓▒
 ░ ▓██▄   ▓██░ ██▓▒▒██░   ▒██  ▀█▄ ▒ ▓██░ ▒░
   ▒   ██▒▒██▄█▓▒ ▒▒██░   ░██▄▄▄▄██░ ▓██▓ ░ 
 ▒██████▒▒▒██▒ ░  ░░██████▒▓█   ▓██▒ ▒██▒ ░ 
 ▒ ▒▓▒ ▒ ░▒▓▒░ ░  ░░ ▒░▓  ░▒▒   ▓▒█░ ▒ ░░   
 ░ ░▒  ░ ░░▒ ░     ░ ░ ▒  ░ ▒   ▒▒ ░   ░    
 ░  ░  ░  ░░         ░ ░    ░   ▒    ░      
       ░               ░  ░     ░  ░        

	SPugium Learning Attack Terminator

```

# Firewall concept
1. *Blacklist* (Global listings of bad IP's)
2. *Whitelist* (Admin IP's)
3. *Blocklist* (Observed bad IP's. Eg. fail2ban, modsecurity etc.)
4. *Service rules*

The order will make the network secure up to a certain point, but this will 
have the effect of slowing down legitimate traffic. 

This is where we use *connection tracking* to speed things up:
If the first packet of a packetstream is not blocked the stream
gets and ESTABLISHED mark. As this is one of the first rules 
every packet sees we ACCEPT those. This state makes stuff
fast as can be.

The big advantage of using the state machine/connection tracking is that 
we can DROP all outgoing except for ESTABLISHED/RELATED. 

```
CLIENT        STATE      PORT     SERVER

[SYN]       ==[N/A]==>   [N/A]    [ACCEPT]   ---|											
[ACCEPT]    <=[N/A]===   [N/A]    [SYNACK]      |--- TCP handshake
[ACK]       ==[N/A]==>   [N/A]    [OPEN]     ---|


[GET /]     ==[NEW]==>   [80]     [ACCEPT]   ---|
[ACCEPT]    <=[EST]===   [51234]  [SEND]        |
[ACCEPT]    <=[EST]===   [51234]  [SEND]        |--- Data request and stream
[ACCEPT]    <=[EST]===   [51234]  [SEND]        |
[ACCEPT]    <=[EST]===   [51234]  [SEND]     ---|

Etc...
```

So even with DROP or REJECT of all outgoing traffic except for ESTABLISHED
we get the packet stream to work. This is great to stop attacker that try
to get revershed shells to work or attacks that download shellcode/malware.


