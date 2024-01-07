#!/bin/bash

# ANSI color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
CYAN="\033[0;36m"
RESET="\033[0m"

# Function to curl a site via TLS and print the connection information.
check-cert() {
    if [ -z "$1" ]; then
        echo -e "${YELLOW}Usage: check <domain.tld> -cert to connect via HTTPS and print TLS connection information.${RESET}"
        return 1
    fi
    local tls_info
    tls_info=$(curl --insecure -vvI "https://$1" 2>&1 | awk -v green="$GREEN" -v cyan="$CYAN" -v magenta="$MAGENTA" -v yellow="$YELLOW" -v blue="$BLUE" -v red="$RED" -v reset="$RESET" '
    /^(\* SSL connection using|\* ALPN, server accepted|\* Server certificate:)/ { print blue $0 reset; next }
    /^\*  subject:/ { print green $0 reset; next }
    /^\*  (start|expire) date:/ { print yellow $0 reset; next }
    /^\*  issuer:/ { print magenta $0 reset; next }
    /^\*  SSL certificate verify result:|Using HTTP2, server supports multiplexing|Connection state changed|Copying HTTP|Using Stream ID|Connection/ { print reset $0 reset; next }
    ')
    # Check if the TLS connection check failed
    if [ -z "$tls_info" ]; then
        echo -e "${RED}Failed to establish a TLS connection. Retrying without modifications...${RESET}"
        # Retry the TLS connection check without modifications
        tls_info=$(curl --insecure -vvI "https://$1" 2>&1)
        
        if [ -z "$tls_info" ]; then
        echo -e "${RED}Failed to establish a TLS connection even on retry. Check the domain or try again.${RESET}"
            return 1
        fi
        # Print the TLS connection information after retry
        echo -e "$tls_info"
        echo -e "${RED}Still nothing? There's likely not a SSL certificate on the server!${RESET}"
        echo -e "${MAGENTA}You can see the certificate chain using the -ssl flag${RESET}"
    else
        # Print the TLS connection information if the initial check succeeded
        echo -e "$tls_info"
    fi
}

    # SSL CERTIFICATE
echo -e "${MAGENTA}------------------------------------------${RESET}"
echo -e "${YELLOW}${1^^} SSL CERTIFICATE INFORMATION${RESET}"
echo -e "${MAGENTA}------------------------------------------${RESET}"
    check-cert "$1"
