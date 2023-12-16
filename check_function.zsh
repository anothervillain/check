# FUNCTIONS NESTED OUTSIDE OF 'check' ITSELF TO AVOID CLUSTERFUCK.
# THESE CAN BE CALLED UPON BY OTHER FUNCTIONS INSIDE 'check' ITSELF.
# USE THE ANSI COLOR CODES BELOW.

# ANSI color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
CYAN="\033[0;36m"
RESET="\033[0m"

# Function to check for NXDOMAIN status in a domain response
check_nxdomain() {
    # Perform a DNS query for the given domain
    local domain_status=$(dig a $1 +cmd)
    # Check if the response contains status: NXDOMAIN
    if echo "$domain_status" | grep -q 'status: NXDOMAIN'; then
        # Check if 'charm.norid.no' is in the result
        if echo "$domain_status" | grep -q 'charm.norid.no'; then
            # Perform a WHOIS query on the domain
            local whois_result=$(whois $1)
            # Check if WHOIS result contains "No match"
            if echo "$whois_result" | grep -q 'No match'; then
                # Print NXDOMAIN status if WHOIS returns "No match" and stop further execution
                echo -e "${RED}NXDOMAIN: No Match found in WHOIS, aborting further checks.${RESET}"
                return 1 # Exiting the function with status 1 to indicate an error or stop condition
            else
                # Print the SOA result if WHOIS returns other output
                echo -e "${RED}The domain $1 is in QUARANTINE @ charm.norid.no${RESET} ${GREEN}--> Owner change!${RESET}"
                return 1 # Exiting the function with status 1 to indicate an error or stop condition
            fi
        else
            # Print NXDOMAIN if no other values are found
            echo -e "${RED}NXDOMAIN: Non-existent domain, aborting further checks.${RESET}"
            echo -e "${YELLOW}Please verify that you entered the correct domain name.${RESET}"
            return 1 # Exiting the function with status 1 to indicate an error or stop condition
        fi
    fi
}
# Function to ping a domain and store the outcome, only informs if the domain is not reachable.
check_reachable() {
    local ping_result=$(ping -c 1 $1)
    if echo "$ping_result" | grep -q '1 packets transmitted, 0 received'; then
        echo -e "${RED}The domain is not reachable (using ping $1).${RESET}"
    fi
}

# Function to convert subdomain to FQDN during WHOIS lookup.
subdomain_to_fqdn() {
    local domain=$1
    local main_domain="${domain##*.}" 
    domain="${domain%.*}"             
    main_domain="${domain##*.}.$main_domain"
    if [[ "$main_domain" != "$1" ]]; then
        echo -e "${RED}$1 doesn't look like a FQDN! ${GREEN}WHOIS for $main_domain:${RESET}" >&2
    fi
    echo "$main_domain"
}

# Main function to check most interesting information about any given domain.
check() {
    # Welcome message & spinner animation
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
for _ in {1..1}; do
    spin
done
printf "\r${GREEN}------------------------------------------ ↓${RESET}"
# Help section
echo
    if [ "$1" = "--help" ]; then
        echo -e "${GREEN}Usage: check domain.tld${RESET}"
        echo "  ${BLUE}Performs the following checks on a domain name:"${RESET}
        echo "  ${YELLOW}> Looks up any A records and potential AAAA records${RESET}"
        echo "  ${GREEN}--> and checks if there are any WEBFORWARD or _redir (301) forwarding records.${RESET}"
        echo "  ${GREEN}> If the domain is forwarding requests from root to www, it'll say it's forwarding.${RESET}"
        echo "  ${YELLOW}> Pulls the MX and SPF records, even if a special 'SPF' field has been used.${RESET}"
        echo "  ${YELLOW}> Checks what Nameservers (NS) the domain answers to.${RESET}"
        echo "  ${YELLOW}> Attempts to do a reverse-dns lookup of the domains primary A and/or AAAA record.${RESET}" 
        echo "  ${GREEN}--> This is the server that the IP from the A record answers to.${RESET}"
        echo "  ${YELLOW}> A secondary function if reverse dns lookup fails can be used 'digx' ${RESET}"
        echo "  ${YELLOW}> Does a whois-lookup of the domain name,${RESET} ${RED}this might fail because of formatting!${RESET}"
        echo "  ${GREEN}--> If the domain is a .no-domain, a secondary whois on the REG handle will be performed.${RESET}"
        echo "  ${YELLOW}> Checks if the domain is on any known blocklists.${RESET}"
        echo "  ${GREEN}--> A secondary function 'blocklist' can be used to look up domain.tld, IPv4 or IPv6 addresses.${RESET}"
        return
    fi
        if [ -z "$1" ]; then
            echo -e "Use ${GREEN}check domain.tld${RESET} or ${YELLOW}check --help${RESET} for more information."
            return
        fi
    # EMPTY INPUT
    if [ -z "$1" ]; then
        echo -e "Use ${GREEN}check domain.tld${RESET} or ${YELLOW}check --help${RESET} for more information."
        return
    fi
    # NXDOMAIN CHECK
    check_nxdomain $1 || return
    # PING CHECK
    #check_reachable $1 || return
    # A RECORD(S)
    echo -e "${YELLOW}A RECORD(S)${RESET}"
    a_result=$(dig a "$1" +short)
    if [ -z "$a_result" ]; then
        echo -e "${RED}No A record found for $1${RESET}"
    else
        echo -e "${GREEN}$a_result${RESET}"
    fi
    # AAAA RECORD(S)
    aaaa_result=$(dig aaaa "$1" +short)
    if [[ -n "$aaaa_result" && ! $aaaa_result =~ "(empty label)" ]]; then
        echo -e "${YELLOW}AAAA RECORD(S)${RESET}"
        echo -e "${GREEN}$aaaa_result${RESET}"
    fi
    # HTTP, WEB, REDIR, AND WWW FORWARDING CHECK
    http_status=$(curl -s -o /dev/null -w "%{http_code}" -L --head "https://$1")
    redirect_url=$(curl -s -L -I "https://$1" | grep -i ^Location: | tail -1 | cut -d ' ' -f 2)
    # Check for HTTP status-based forwarding
    case "$http_status" in
    301|302|303|307|308)
        echo -e "${YELLOW}WEB FORWARDING RECORD (HTTP $http_status)${RESET}"
        echo -e "${GREEN}The domain $1 is forwarding with HTTP $http_status status.${RESET}"
        # Check for root to www forwarding
        if [[ "$redirect_url" =~ https://www.$1/? ]]; then
            echo -e "${GREEN}The domain is forwarding from root --> www.$1${RESET}"
        fi
esac
    # Check for _redir TXT forwarding
    txt_redir_result=$(dig +short txt "_redir.$1")
    if [ -n "$txt_redir_result" ]; then
        echo -e "${YELLOW}TXT FORWARDING USING _redir${RESET}"
        echo -e "${GREEN}$txt_redir_result${RESET}"
    fi
    # Check for PARKED TXT records.
    parked_txt_record=$(dig +short txt "$1" | grep -i "^\"parked")
    if [ -n "$parked_txt_record" ]; then
    echo -e "${YELLOW}PARKED DOMAIN${RESET}"
    echo -e "${GREEN}The domain $1 is parked in TXT.${RESET}"
    else
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
# REVERSE DNS LOOKUP
echo -e "${YELLOW}REVERSE DNS LOOKUP${RESET}"
# Check and perform Reverse DNS lookup for A record
reverse_result_a=$(dig -x "$a_result" +short)
# Compare A result with specific IP address and handle different scenarios
if [ "$a_result" = "104.37.39.71" ]; then
    echo -e "${GREEN}This is our redirect proxy${RESET}" "${CYAN}(104.37.39.71)${RESET}" 
    echo -e "${BLUE}Domain has default A record${RESET}" "${MAGENTA}or it's --> forwarding${RESET}"
elif [[ -z "$reverse_result_a" || $reverse_result_a == *"SOA"* ]]; then
    echo -e "${RED}Failed${RESET}" "${YELLOW}(A record)${RESET}" "${GREEN}or it was SOA.${RESET}"
else
    echo -e "${GREEN}$reverse_result_a${RESET}"
fi
# Check and perform Reverse DNS lookup for AAAA record
if [[ -n "$aaaa_result" && ! $aaaa_result == *"SOA"* ]]; then
    # Extract the first valid IPv6 address
    local first_aaaa_address=$(echo "$aaaa_result" | head -n 1)
    reverse_result_aaaa=$(dig -x "$first_aaaa_address" +short)

    # Handle different scenarios for AAAA record
    if [[ -n "$reverse_result_aaaa" && ! $reverse_result_aaaa == *"SOA"* ]]; then
        echo -e "${GREEN}$reverse_result_aaaa${RESET} ${YELLOW}(AAAA)${RESET}"
    else
        echo -e "${RED}Failed${RESET}" "${YELLOW}(AAAA record)${RESET}" "${GREEN}or it was SOA.${RESET}"
    fi
fi
# REGISTRAR
local domain=$1
echo -e "${YELLOW}REGISTRAR${RESET}"
# Convert subdomain to FQDN
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
    # Extract registrar name if 'Registrar Handle' is found
    if [ -n "$registrar_result" ]; then
        local registrar_name=$(echo "$registrar_result" | xargs whois | grep "Registrar Name" | sed 's/.*: //' | head -n 1)
    fi
fi
# Check for registrar result
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
    # Function to check SSL certificate without --insecure flag
check_ssl_certificate() {
    local domain=$1
    local ssl_info
    ssl_info=$(curl --max-time 10 -vvI "https://$domain" 2>&1 | awk -v cyan="$CYAN" -v yellow="$YELLOW" -v magenta="$MAGENTA" -v reset="$RESET" '
        /^\*  subject:/ { print cyan $0 reset }
        /^\*  (start|expire) date:/ { print yellow $0 reset }
        /^\*  issuer:/ { print magenta $0 reset }
    ')
    if [ -z "$ssl_info" ]; then
        echo -e "${RED}Failed to retrieve SSL certificate information. Try using checkcert for detailed diagnostics.${RESET}"
    else
        echo -e "$ssl_info"
        echo -e "${GREEN}*  Use${RESET}" "${BLUE}checkcert${RESET}" "${GREEN}or${RESET}" "${BLUE}checkssl${RESET}" "${GREEN}for more info${RESET}"
    fi
}
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
    echo -e "${GREEN}TLS Connection Information for $1 (After Retry):${RESET}"
    echo -e "$tls_info"
    echo "${RED}There's likely not a SSL certificate on the server.${RESET}"
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