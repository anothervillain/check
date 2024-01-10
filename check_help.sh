#!/usr/bin/bash

# ANSI color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
CYAN="\033[0;36m"
RESET="\033[0m"

# Function to display help information
show_help() {
    echo -e "${MAGENTA}--------------------------------------------${RESET}"
    echo -e "${YELLOW}CHECK HELP SECTION AND EXPLANATION CENTRE${RESET}"
    echo -e "${MAGENTA}--------------------------------------------${RESET}"
    echo -e "${BLUE}The script can make mistakes, do your own research!${RESET}"
    echo
    echo -e "${YELLOW}* Preliminary checks:${RESET}"
    echo -e "${MAGENTA}-----------------------${RESET}"
    echo -e "${RED}* NXDOMAIN:${RESET}" "${GREEN}Is the domain valid and does it exist?${RESET}"
    echo -e "${RED}* QUARANTINE:${RESET}" "${GREEN}Is the domain in Quarantine (this is only for .no domains).${RESET}"
    echo -e "${RED}* REGISTRAR:${RESET}" "${GREEN}Who is the registrar for the domain, alternatively the Registry (White Label).${RESET}"
    echo -e "${RED}* DNS ADMINISTRATION:${RESET}" "${GREEN}Guesses where the domains DNS is edited from.${RESET}"
    echo "* There's a 20 second cache on running check <domain.tld> so you have time to -flag without getting repeated information."
    echo
    echo -e "${YELLOW}<check>${RESET}" "${BLUE}allows for flags so you pull only relevant info:${RESET}" "${CYAN}-all, -host -mail, -cert, -ssl -rdns${RESET}"
    echo
    echo -e "${YELLOW}check <domain.tld> -all${RESET}"
    echo -e "${GREEN}Pulls -host, -mail and -cert scripts into one output like the 'original' check function.${RESET}"
    echo
    echo -e "${YELLOW}check <domain.tld> -host${RESET}" 
    echo -e "${GREEN}Grabs information in regards to hosting, mostly DNS records. And makes an estimated guess.${RESET}"
    echo
    echo -e "${YELLOW}check <domain.tld> -mail${RESET}"
    echo -e "${GREEN}Shows relevant DNS records and uses basic logic to guess email hosting provider.${RESET}"
    echo
    echo -e "${YELLOW}check <domain.tld> -cert${RESET}"
    echo -e "${GREEN}Uses 'curl' to connect to the domain and show TLS information regarding SSL/TLS.${RESET}"
    echo
    echo -e "${YELLOW}check <domain.tld> -ssl${RESET}"
    echo -e "${GREEN}Connects to the domain name via OpenSSL to display the full certificate chain.${RESET}"
    echo
    echo -e "${YELLOW}check <domain.tld> -rdns${RESET}"
    echo -e "${GREEN}Python script that pulls PTR or SOA information from all A and AAAA records.${RESET}\n"
}
