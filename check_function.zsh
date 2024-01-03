# ANSI color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
CYAN="\033[0;36m"
RESET="\033[0m"

# Function to check domain header for status: NXDOMAIN
check_nxdomain() {
    # Check if the input domain contains two consecutive periods
    if echo "$1" | grep -q '\.\.'; then
        echo -e "${RED}Invalid domain: two consecutive periods (dns..tld), aborting further checks.${RESET}"
        return 1 # Stopping the script from running further here
    fi
    # Perform a prelimiary 'dig a' on the given domain
    local domain_status=$(dig a $1 +cmd)
    # Check if the header contains status: NXDOMAIN
    if echo "$domain_status" | grep -q 'status: NXDOMAIN'; then
        # Check if 'charm.norid.no' is in SOA for the domain
        if echo "$domain_status" | grep -q 'charm.norid.no'; then
            # Perform a WHOIS on the domain
            local whois_result=$(whois $1)
            # Check if WHOIS result contains "No match"
            if echo "$whois_result" | grep -q 'No match'; then
                # WHOIS check for .no domains specifically to determine if the domain is NXDOMAIN
                echo -e "${RED}NXDOMAIN:${RESET}" ${YELLOW}"No Match"${RESET}" returned from "${BLUE}Norid${RESET}", aborting further checks.${RESET}"
                echo -e "${YELLOW}This might be an error, do your research! UwU${RESET}"
                return 1 # Stopping the script from running further here
            else
                # If domain has status:NXDOMAIN, and SOA 'charm.norid.no' and the whois equals No match = QUARANTINE
                echo -e "${RED}$1 looks to be in QUARANTINE${RESET}" "${YELLOW}SOA:${RESET}" "${BLUE}charm.norid.no.${RESET}"
                echo -e "${YELLOW}This might be an error, do your research! UwU${RESET}"
                return 1 # Stopping the script from running further here
            fi
        else
            # If the NXDOMAIN status is found for any other TLD.
            echo -e "${RED}NXDOMAIN: Non-existent domain, aborting further checks.${RESET}"
            echo -e "${YELLOW}Please verify that you entered the correct domain name.${RESET}"
            return 1 # Stopping the script from running further here
        fi
    fi
}

# Function to convert subdomain to FQDN for WHOIS lookup
subdomain_to_fqdn() {
    local domain=$1
    # Array of specific subdomains to exclude
    local exclude_subdomains=("kommune.no")
    # Extract the top-level domain (TLD) and second-level domain (SLD) from the domain name
    local tld="${domain##*.}"
    local second_level="${domain%.*}"
    local sld="${second_level##*.}.$tld"
    # Check if the SLD matches any excluded subdomain patterns
    for excluded_domain in "${exclude_subdomains[@]}"; do
        if [[ "$sld" == *"$excluded_domain" ]]; then
            echo "$domain" # Output the original domain as it matches the exclusion pattern
            return 0
        fi
    done
    # Convert to FQDN
    local main_domain="$sld"
    if [[ "$main_domain" != "$1" ]]; then
        echo -e "${RED}$1 doesn't look like a FQDN${RESET}" "${GREEN}WHOIS for $main_domain:${RESET}" >&2
    fi
    echo "$main_domain"
}

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
        echo -e "${RED}Failed to retrieve SSL certificate information. Try using checkcert for detailed diagnostics.${RESET}"
    else
        echo -e "$ssl_info"
        echo -e "${GREEN}*  Use${RESET}" "${BLUE}checkcert${RESET}" "${GREEN}or${RESET}" "${BLUE}checkssl${RESET}" "${GREEN}for more info${RESET}"
    fi
}

# Reverse DNS Lookup using FQDN name, able to check all IPs.
PYTHON_SCRIPT_PATH="/home/$USER/check/rdns.py"
# Function to execute the Python script with the provided domain
rdns() {
    if [ ! -f "$PYTHON_SCRIPT_PATH" ]; then
        echo "Error: rdns.py not found at the specified path."
        return 1
    fi
    if [ -z "$1" ]; then
        echo "Usage: rdns <domain.tld>"
        return 1
    fi
    python3 "$PYTHON_SCRIPT_PATH" "$@"
}

# THE FUNCTION STARTS HERE! :)
check() {
    echo "Checking for information on $1:" | lolcat
    spinner=( '/' '-' '\' '|' )
    colors=("$RED" "$GREEN" "$YELLOW" "$BLUE" "$MAGENTA" "$CYAN")
    
    spin(){
        local i=0
        for s in "${spinner[@]}"; do
            color=${colors[$((i % ${#colors[@]}))]}
            printf "\r${color}%s${RESET}" "$s"
            sleep 0.1
            ((i++))
        done
    }
    for _ in {1..2}; do
        spin
    done
    printf "\r${GREEN}------------------------------------------ ↓${RESET}"
    # HELP SECTION ## NEEDS REWRITE
    echo
    if [ "$1" = "--help" ]; then
        echo -e "${GREEN}Usage: check domain.tld${RESET}"
        echo "  ${BLUE}PRIMARY FUNCTIONALITY:${RESET}"
        echo "  ${YELLOW}> A and AAAA Records: Retrieves A (IPv4) and AAAA (IPv6) DNS records.${RESET}"
        echo "  ${YELLOW}> HTTP-based forwarding (redirection) of all kinds including _redir.${RESET}"
        echo "  ${YELLOW}> MX Records: Checks which mailservers the domain uses..${RESET}"
        echo "  ${YELLOW}> SPF Records: Looks for SPF records to identify authorized senders.${RESET}"
        echo "  ${YELLOW}> NS Records: Retrieves Name Server (NS) for DNS management of the domain.${RESET}"
        echo "  ${YELLOW}> Registrar Information from WHOIS: Displays the name only.${RESET}"
        echo "  ${YELLOW}> Additional WHOIS for .no domains on the REG handle to convert to [NAME].${RESET}"
        echo "  ${YELLOW}> SSL Information: Using curl, awk and openssl to test SSL connectivity.${RESET}"
        echo "  ${YELLOW}> Reverse DNS Lookup: Attempts a reverse-DNS lookup of the domains A and/or AAAA records.${RESET}"
        echo "  ${YELLOW}> Guesses the hosting provider based on a few criteria, prone to mistakes!.${RESET}"
        echo "  ${BLUE}ADD-ON FUNCTIONALITY:${RESET}"
        echo "  ${MAGENTA}> checkcert:${RESET}" "${RED}Curls for TLS information.${RESET}"
        echo "  ${MAGENTA}> checkssl:${RESET}" "${RED}Connect to the hostname and display certificate chain.${RESET}"
        echo "  ${MAGENTA}> rdns:${RESET}" "${RED}Lookup a domains PTR and SOA.${RESET}"
        echo "  ${CYAN}> Note: This script can be produce incorrect responses.${RESET}"
        return
    fi
    if [ -z "$1" ]; then
        echo -e "Use ${GREEN}check domain.tld${RESET} or ${YELLOW}check --help${RESET} for more information."
        return
    fi
    
    # NXDOMAIN & QUARANTINE CHECK
    check_nxdomain $1 || return
    
    # CLEAR PREVIOUS RECORDS FROM FILES (used for RDNS later)
    echo "" > a_results.txt
    echo "" > aaaa_results.txt
    # Writing the domain to a file for the .py script
    echo "$1" > current_domain.txt

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
    if [[ -n "$aaaa_result" && ! $aaaa_result =~ "(empty label)" ]]; then
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
            # Check for forwarding from root to www
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
    # Check for PARKED TXT records (Can probably flesh this one out)
    parked_txt_record=$(dig +short txt "$1" | grep -i "^\"parked")
    if [ -n "$parked_txt_record" ]; then
        echo -e "${YELLOW}PARKED DOMAIN${RESET}"
        echo -e "${GREEN}The domain $1 looks like it's parked${RESET}"
    fi
    
    # MX RECORD(S)
    echo -e "${YELLOW}MX RECORD(S)${RESET}"
    mx_result=$(dig mx "$1" +short)
    if [ -z "$mx_result" ]; then
        echo -e "${RED}No MX record found for $1${RESET}"
    else
        echo -e "${GREEN}$mx_result${RESET}"
    fi
    
    # SPF RECORD
    echo -e "${YELLOW}SPF RECORD${RESET}"
    spf_result=$(dig +short txt "$1" | grep 'v=spf')
    if [ -z "$spf_result" ]; then
        echo -e "${RED}No SPF record found for $1${RESET}"
    else
        echo -e "${GREEN}$spf_result${RESET}"
    fi
    spf_result=$(dig +short spf "$1" | grep 'v=spf')
    if [ -n "$spf_result" ]; then
        echo -e "${GREEN}Custom 'SPF' type DNS record found: $spf_result${RESET}"
        echo -e "${RED}These types of records work poorly!${RESET}"
    fi
    
    # NAMESERVERS
    echo -e "${YELLOW}NAMESERVERS${RESET}"
    ns_result=$(dig ns "$1" +short)
    if [ -z "$ns_result" ]; then
        echo -e "${RED}No nameservers found for $1${RESET}"
    else
        echo -e "${GREEN}$ns_result${RESET}"
    fi
        
    # REVERSE DNS LOOKUP (Python)
    python3 ~/check/reverse-dns-lookup.py
    
    # HOST GUESSER (Python)
    python3 ~/check/hostguess.py $1
    
    # REGISTRAR
    local domain=$1
    echo -e "${YELLOW}REGISTRAR${RESET}"
    # Convert subdomain to FQDN (or keep as is if it's an excluded subdomain)
    local main_domain=$(subdomain_to_fqdn "$domain")
    # First lookup for registrar result in single-line format
    local registrar_result_single_line=$(whois "$main_domain" | grep -E 'Registrar:' | sed -n 's/Registrar: *//p' | head -n 1 | xargs)
    # Second lookup for registrar result in two-line format
    local registrar_result_two_line=$(whois "$main_domain" | grep -A1 -E 'Registrar:' | awk '/Registrar:/{getline; if ($0 !~ /^ *$/) print; else exit}' | sed 's/^ *//' | xargs)
    # Combine the results, preferring single-line result if available
    local registrar_result=${registrar_result_single_line:-$registrar_result_two_line}
    # If not found, attempt to find using 'Registrar Handle'
    if [ -z "$registrar_result" ]; then
        registrar_result=$(whois "$main_domain" | grep -A1 -E 'Registrar Handle' | sed -n 's/Registrar Handle...........: *//p' | head -n 1 | xargs)
        # Extract registrar name if 'Registrar Handle' is found and append it to the output []
        if [ -n "$registrar_result" ]; then
            local registrar_name=$(echo "$registrar_result" | xargs whois | grep "Registrar Name" | sed 's/.*: //' | head -n 1)
        fi
    fi
    # Using the extracted name from the previous statement to
    if [ -n "$registrar_result" ]; then
        # Check if registrar name is found and if the result starts with 'REG'
        if [ -n "$registrar_name" ] && [[ "${registrar_result:0:3}" == "REG" ]]; then
            echo -e "${GREEN}$registrar_result${RESET}" "${CYAN}[$registrar_name]${RESET}"
        else
            echo -e "${GREEN}$registrar_result${RESET}"
        fi
    else
        echo -e "${RED}No Registrar information found for $main_domain${RESET}"
        echo -e "Perform ${YELLOW}whois $main_domain${RESET} instead"
    fi
    
    # SSL CERTIFICATE
    echo -e "${YELLOW}SSL CERTIFICATE${RESET}"
    check_ssl_certificate "$1"
}

# ADD-ON FUNCTIONALITY
# checkssl to connect via openssl and view certificate chain.
# checkcert to show SSL information (sanizied output) and retry if that fails.

# Function to curl a site via TLS and print the connection information.
function checkcert() {
    if [ -z "$1" ]; then
        echo -e "${YELLOW}Usage: checkcert <domain.tld> to connect via HTTPS and print TLS connection information.${RESET}"
        return 1
    fi
    local tls_info=$(curl --insecure -vvI "https://$1" 2>&1 | awk -v green="$GREEN" -v cyan="$CYAN" -v magenta="$MAGENTA" -v yellow="$YELLOW" -v blue="$BLUE" -v red="$RED" -v reset="$RESET" '
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
        echo -e "${GREEN}TLS connection information for $1 after retrying with no sanitized output:${RESET}"
        echo -e "$tls_info"
        echo "${RED}Still nothing? There's likely not a SSL certificate on the server!${RESET}"
    else
        # Print the TLS connection information if the initial check succeeded
        echo -e "${GREEN}TLS Connection Information for $1:${RESET}"
        echo -e "$tls_info"
    fi
}

# Connect to a hostname using openssl to show complete certificate chain.
checkssl() {
    openssl s_client --showcerts --connect "$1:443" 2>/dev/null | awk -v RED="$RED" -v GREEN="$GREEN" -v YELLOW="$YELLOW" -v BLUE="$BLUE" -v MAGENTA="$MAGENTA" -v CYAN="$CYAN" -v RESET="$RESET" '
    /Server certificate/ { print CYAN $0 RESET; next }
    /^subject=/ { print GREEN $0 RESET; next }
    /^issuer=/ { print MAGENTA $0 RESET; next }
    /SSL handshake/ { print BLUE $0 RESET; next }
    /Verification/ { print YELLOW $0 RESET; next }
    /(s|i|a|v):/ { print RED $0 RESET; next }
    /^-----BEGIN CERTIFICATE-----/, /^-----END CERTIFICATE-----/ { print $0; next }
    { print $0 }
    '
}
