# **About this tool**
Usage: <check domain.tld> to lookup relevant DNS, WHOIS and SSL information in your terminal.

# **Installation and setup**

1) Add **export PATH="check:$PATH"** to your .zshrc
2) Add **source ~/check/check_function.zsh** to your .zshrc
3) (Optional) set an alias for the update script (ex: alias updatecheck='update_check.sh')
4) git clone https://github.com/zhk3r/check.git
5) chmod +x ~/check/update_check.sh
6) Restart your terminal.

# **Preliminary queries before contiuing with checks** 
1) Checks for 'NXDOMAIN' status in the header-information from 'dig a'.
2) Checks whether or not the domain has SOA beginning with 'charm.norid.no'
3) Checks that the domain is reachable using 'ping' command.
   
- If the domain has the 'NXDOMAIN' status the script will inform about it and stop. 
- If the domain has SOA 'charm.norid.no' the script will inform about it and stop. 
- If the domain is not reachable using 'ping' the script will inform, but continue with the rest of the checks.

# **Domain information**
The script will look for the following information and try to filter it out: 

1) A and AAAA records.
2) Forwarding of all types: HTTP-status, redirTXT, DNS, Parked messages and such.
3) MX records
4) SPF records using 'TXT' type and custom 'SPF' type (the tool will inform if it's the special-type)
5) Nameservers
6) Reverse DNS lookup of the A and AAAA record
- Hardcoded check for 104. SSL proxy.
- Looks up the Apex domains (A) + (AAAA) records and performs a reverse dns lookup.
7) Checks Registrar information, does multiple lookups depending on types of results.
8) SSL certificate CN, start|end date and issuer

# **Output and sanitazion of information**

Some of the functions sanitize the output in order to show only relevant information. Some of these checks include the WHOIS lookup which accounts for a subdomain being input, WHOIS lookup where a secondary lookup is done if 'requirements' are met. Reverse DNS lookup also has rules that sanitizes the information if the result is SOA (example). 

# **Dependencies**

- dig
- whois
- openssl
- curl
- grc
- lolcat
