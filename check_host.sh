#!/usr/bin/bash

# ANSI color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
RESET="\033[0m"

    if [ -z "$1" ]; then
        echo -e "Use ${GREEN}check domain.tld${RESET} or ${YELLOW}check -help${RESET} for more information."
        return
    fi
    
    # CLEAR PREVIOUS RECORDS FROM FILES (used for RDNS later)
    echo "" > a_results.txt
    echo "" > aaaa_results.txt
    # Writing the domain to a file for the .py script
    echo "$1" > current_domain.txt

echo -e "${MAGENTA}------------------------------------------${RESET}"
echo -e "${YELLOW}${1^^} HOSTING RELEVANT INFORMATION${RESET}"
echo -e "${MAGENTA}------------------------------------------${RESET}"

    # A RECORD(S) 
    echo -e "${YELLOW}A RECORD(S)${RESET}"
    a_result=$(dig a "$1" +short)
    if [ -z "$a_result" ]; then
        echo -e "${RED}No A record found for $1${RESET}"
    else
        # Check if the A record is using SSL Redirect Proxy or Default A Record
        if echo "$a_result" | grep -q '104.37.39.71'; then
            echo -e "${GREEN}$a_result${RESET} (SSL Redirect Proxy or default A record)"
        else
            echo -e "${GREEN}$a_result${RESET}"
        fi
        # Store A record result in a file
        echo "$a_result" | tr ' ' '\n' > a_results.txt
    fi

    # AAAA RECORD(S)
    aaaa_result=$(dig aaaa "$1" +short)
    if [[ -n "$aaaa_result" && ! $aaaa_result =~ (empty label) ]]; then
        echo -e "${YELLOW}AAAA RECORD(S)${RESET}"
        echo -e "${GREEN}$aaaa_result${RESET}"
        # Store AAAA record result in a file
        echo "$aaaa_result" | tr ' ' '\n' > aaaa_results.txt
    fi
    
    # HTTP, WEB, REDIR, AND WWW FORWARDING CHECK
    http_status=$(curl -s -o /dev/null -w "%{http_code}" -L --head "https://$1")
    redirect_url=$(curl -s -L -I "https://$1" | grep -i ^Location: | tail -1 | cut -d ' ' -f 2)
    # Check for http-based status-forwarding
    case "$http_status" in
        301|302|303|307|308)
            echo -e "${YELLOW}WEB FORWARDING RECORD (HTTP $http_status)${RESET}"
            echo -e "${GREEN}The domain $1 is forwarding with HTTP $http_status status.${RESET}"
            # Check for forwarding from root to www $domain
            if [[ "$redirect_url" =~ https://www.$1/? ]]; then
                echo -e "${GREEN}The domain is forwarding from $1 --> www.$1${RESET}"
            fi
    esac
    # Check for _redir TXT forwarding
    txt_redir_result=$(dig +short txt "_redir.$1")
    if [ -n "$txt_redir_result" ]; then
        echo -e "${YELLOW}WEB FORWARDING RECORD (_REDIR)${RESET}" 
        echo -e "${GREEN}$txt_redir_result${RESET}"
    fi
    # Check for PARKED TXT records ## NOT FLESHED OUT. WORKS POORLY.
    parked_txt_record=$(dig +short txt "$1" | grep -i "^\"parked")
    if [ -n "$parked_txt_record" ]; then
        echo -e "${YELLOW}PARKED DOMAIN${RESET}"
        echo -e "${GREEN}The domain $1 looks like it's parked${RESET}"
    fi

# NAMESERVERS
echo -e "${YELLOW}NAMESERVERS${RESET}"
ns_result=$(dig ns "$1" +noall +answer | awk '$4=="NS" {print $5}')
if [ -z "$ns_result" ]; then
    echo -e "${RED}No nameservers found for $1${RESET}"
else
    while read -r ns; do
        # Fetch the IP address for each nameserver
        ip=$(dig +short "$ns")
        if [ -z "$ip" ]; then
            # Output the nameserver without IP (IP not found)
            echo -e "${GREEN}${ns}${RESET}"
        else
            # Output the nameserver with its IP
            echo -e "${GREEN}${ns} ${MAGENTA}${ip}${RESET}"
        fi
    done <<< "$ns_result"
fi

    # REVERSE DNS LOOKUP (Python)
    python3 ~/check/reverse-dns-lookup.py

    # HOST GUESSER (Python)
    python3 ~/check/hostguess.py "$1"

# Function to check SSL certificate without --insecure flag
check_ssl_certificate() {
    local domain=$1
    local ssl_info
    ssl_info=$(curl --max-time 10 -vvI "https://$domain" 2>&1 | iconv -f ISO-8859-1 -t UTF-8 | awk -v cyan="$CYAN" -v yellow="$YELLOW" -v magenta="$MAGENTA" -v reset="$RESET" '
        /^\*  subject:/ {
            match($0, /CN=[^,]*/)
            cn = substr($0, RSTART, RLENGTH)
            print cyan "subject: " cn reset
        }
        /^\*  (start|expire) date:/ { print yellow $0 reset }
        /^\*  issuer:/ { gsub(/^\*  issuer: /, ""); print magenta "*  issuer: " $0 reset }
    ')
    if [ -z "$ssl_info" ]; then
        echo -e "${RED}Failed to retrieve SSL certificate information. Try using -cert for detailed diagnostics.${RESET}"
    else
        echo -e "$ssl_info"
        echo -e "${GREEN}*  Use${RESET}" "${BLUE}-cert ${RESET}" "${GREEN}or${RESET}" "${BLUE}-ssl${RESET}" "${GREEN}for more info${RESET}"
    fi
}

    # SSL CERTIFICATE
    echo -e "${MAGENTA}------------------------------------------${RESET}"
    echo -e "${YELLOW}${1^^} SSL CERTIFICATE INFORMATION${RESET}"
    echo -e "${MAGENTA}------------------------------------------${RESET}"
    check_ssl_certificate "$1"

    # DELETE GENERATED FILES OR USE IN .PY SCRIPTS | NO CACHE BABE
    rm -rf "current_domain.txt" "a_results.txt" "aaaa_results.txt"
