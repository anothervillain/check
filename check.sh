#!/bin/bash

# ANSI color codes
RED="\e[0;31m"
GREEN="\e[0;32m"
YELLOW="\e[0;33m"
BLUE="\e[0;34m"
MAGENTA="\e[0;35m"
CYAN="\e[0;36m"
RESET="\e[0m"

# Sourcing help to avoid double-posts
source ~/check/check_help.sh

check_domain() {
    local domain=$1
    # Check for invalid domain format
    if echo "$domain" | grep -q '\.\.'; then
        echo -e "${RED}Invalid domain format, fat fingers?${RESET}"
        return 1
    fi
    # Check domain existence and quarantine status
    local domain_status="$(dig +short A "$domain")"
    local whois_status="$(whois "$domain")" | grep -q 'No match';
    if [[ -z "$domain_status" ]]; then
        echo -e "${RED}NXDOMAIN: The domain${RESET}" "${CYAN}$domain${RESET}" "${RED}does not exist.${RESET}"
        echo -e "${YELLOW}Ensure you wrote${RESET}" "${CYAN}$domain${RESET}" "${YELLOW}correctly!${RESET}"
        return 1
    elif echo "$whois_status" | grep -q 'No match'; then
        echo -e "${YELLOW}Domain${RESET}" "${BLUE}$domain${RESET}" "${YELLOW}is in${RESET}" "${MAGENTA}QUARANTINE${RESET}"
        return 1
    else
        echo -e "${YELLOW}The domain${RESET}" "${CYAN}$domain${RESET}" "${GREEN}exists.${RESET}"
    fi
    while (( "$#" )); do
        case "$1" in
            -all)
                call_script "all" "$domain"
                ;;
            -host)
                call_script "host" "$domain"
                ;;
            -mail)
                call_script "cert" "$domain"
                ;;
            -cert)
                call_script "cert" "$domain "
                ;;
            -ssl)
                call_script "ssl" "$domain"
                ;;
            -rdns)
                call_script "rdns" "$domain"
                ;;
            -whois)
                call_script "norid" "$domain"
        esac
        shift # Move to the next argument/flag
    done
}

check_registrar() {
    local domain=$1
    # Perform registrar check
    local registrar_result_single_line
    registrar_result_single_line=$(whois "$domain" | grep -E 'Registrar:' | sed -n 's/Registrar: *//p' | head -n 1 | xargs)
    local registrar_result_two_line
    registrar_result_two_line=$(whois "$domain" | grep -A1 -E 'Registrar:' | awk '/Registrar:/{getline; if ($0 !~ /^ *$/) print; else exit}' | sed 's/^ *//' | xargs)
    local registrar_result
    registrar_result=${registrar_result_single_line:-$registrar_result_two_line}
    # Handle 'Registrar Handle'
    if [ -z "$registrar_result" ]; then
        registrar_result=$(whois "$domain" | grep -A1 -E 'Registrar Handle' | sed -n 's/Registrar Handle...........: *//p' | head -n 1 | xargs)
        if [ -n "$registrar_result" ]; then
            local registrar_name
            registrar_name=$(echo "$registrar_result" | xargs whois | grep "Registrar Name" | sed 's/.*: //' | head -n 1)
            registrar_result="${registrar_result} [${registrar_name}]"
        fi
    fi
    # Prepare registrar information for output
    if [ -n "$registrar_result" ]; then
        echo -e "${YELLOW}Registrar:${RESET}" "${GREEN}$registrar_result${RESET}"
    else
        echo -e "${RED}Could not determine registrar for $domain.${RESET}" "${YELLOW}Perform${RESET} whois $domain ${YELLOW}instead!${RESET}"
    fi
}

# Disable case sensitivity
shopt -s nocasematch
# Associative array to map DNS names to regular expressions
declare -A determine_dns
# Known hosts: Global
determine_dns["Cloudflare"]="cloudflare\\.(net|com|org)"
determine_dns["Amazon AWS"]="awsdns-|amzndns\\.(co\\.uk|com|net|org)"
determine_dns["Google Cloud DNS"]="googledomains\\.com|google\\.com"
determine_dns["Microsoft Azure"]="azure-dns\\.com"
determine_dns["GoDaddy"]="domaincontrol\\.com|godaddy\\.com"
determine_dns["Netlify"]="nsone\\.net"
determine_dns["NameSRS"]="dnsnode\\.net"
determine_dns["Linpro"]="linpro\\.net"
determine_dns["MarkMonitor Inc"]="\.markmonitor\\.(zone|com)"
# Known hosts: Our brands
determine_dns["SYSE"]="syse\\.no"
determine_dns["Legacy ProISP"]="ns1.proisp.no|ns2.proisp.no"
determine_dns["ProISP"]="ns01.proisp.no|ns02.proisp.no"
determine_dns["Digital Garden"]="uniweb\\.no|fastname\\.no|\\.no\\.brand\\.one\\.com|ns02\\.no\\.brand\\.one\\.com"
determine_dns["One.com"]="one-(net|com|org)|one-dns\\.(net|com|org)"
# Known hosts: Local providers
determine_dns["Domeneshop"]="hyp.net"
determine_dns["Netclient Services"]="netclient\\.(no|net|com|org)"

# Enable case sensitivity
shopt -s nocasematch

# Function to guess DNS administration based on NS conversion to company-name
guess_dns() {
    local domain=$1
    local ns_results=($(dig ns "$domain" +short))
    if [ -z "$ns_results" ]; then
        # Exit function if no nameservers are found
        return 1
    fi

    local matched_services=()
    for ns in "${ns_results[@]}"; do
        for service in "${!determine_dns[@]}"; do
            local pattern="${determine_dns[$service]}"
            if [[ "$ns" =~ $pattern ]]; then
                # Add service to matched_services array if not already included
                if [[ ! " ${matched_services[*]} " =~ " $service " ]]; then
                    matched_services+=("$service")
                fi
                break # Exit the inner loop
            fi
        done
    done

    if [ ${#matched_services[@]} -gt 0 ]; then
        # Construct a string of matched services with colored output
        local services_str=""
        local color=$BLUE  # Start with blue color for the first service
        for i in "${matched_services[@]}"; do
            services_str+="${color}$i${RESET}"
            color=$CYAN  # Change color to cyan for subsequent services
            # Add separator if not the last service
            if [ "$i" != "${matched_services[-1]}" ]; then
                services_str+=" ${YELLOW}&${RESET} "
            fi
        done

        # Append "Redundancy?" in green if more than one service is matched
        if [ ${#matched_services[@]} -gt 1 ]; then
            services_str+=" ${GREEN}(Multiple NS. Redundant maybe)${RESET}"
        fi

        echo -e "${YELLOW}DNS management:${RESET}" "$services_str"
    fi
}

# Function to call the appropriate script based on flag
call_script() {
    local script_name="$1"
    local domain="$2"
    # Define the full path to the script directory
    local script_dir="$HOME/check"
    # Call the script directly by its full path
    local script_to_call="${script_dir}/check_${script_name}.sh"
    if [[ -x "$script_to_call" ]]; then
        "$script_to_call" "$domain"
    else
        echo -e "${RED}Error: Script for $script_name not found or not executable.${RESET}"
        return 1
    fi
}

# Define a path for the temporary file
tmp_file="/tmp/check_sh_last_run"

# Function to record the last run
record_last_run() {
    local domain=$1
    echo "$domain $(date +%s)" > "$tmp_file"
}

# Function to check if registrar info should be pulled again
can_skip_checks() {
    local domain=$1
    local time_frame=15

    if [[ -f "$tmp_file" ]]; then
        read -r last_domain last_time < "$tmp_file"
        local current_time=$(date +%s)
        if [[ "$last_domain" == "$domain" && $((current_time - last_time)) -lt $time_frame ]]; then
            return 0
        fi
    fi
    return 1
}

check() {
    local domain=$1
    if [[ -z "$domain" ]]; then
        echo -e "${YELLOW}Usage:${RESET}" "${GREEN}check domain.tld${RESET}" "${MAGENTA}-flag${RESET}"
        echo -e "${YELLOW}For detailed intstructions type:${RESET}" "${CYAN}check -help${RESET}"
        return
    fi
    if [[ "$domain" == "-help" ]]; then
        show_help
        return
    fi

    local is_domain_valid=true

    # Perform checks only if the domain is not flagged
    if ! [[ "$domain" =~ ^- ]]; then
        if ! $(can_skip_checks "$domain"); then

            echo -e "${MAGENTA}------------------------------------------${RESET}"
            echo -e "${YELLOW}${domain^^} REGISTRATION INFORMATION${RESET}"
            echo -e "${MAGENTA}------------------------------------------${RESET}"

            if ! check_domain "$domain"; then
                is_domain_valid=false
            else
                check_registrar "$domain"
                guess_dns "$domain"
                record_last_run "$domain"
            fi
        fi
    fi

    # Process additional flags
    shift
    while (( "$#" )); do
        local flag=$1
        case "$flag" in
            -all|--all|+all|-a)
                if $is_domain_valid; then
                    # Call scripts for all checks
                    call_script "mail" "$domain"
                    call_script "host" "$domain"
                else
                    echo -e "${RED}Error: Not a valid domain $domain or an unsupported flag $flag.${RESET}"
                fi
                ;;
            -host|--host|-h)
                [ $is_domain_valid == true ] && call_script "host" "$domain"
                ;;
            -mail|--mail|-m|-email)
                [ $is_domain_valid == true ] && call_script "mail" "$domain"
                ;;
            -cert|--cert|-c)
                [ $is_domain_valid == true ] && call_script "cert" "$domain"
                ;;
            -ssl|--ssl|-s)
                [ $is_domain_valid == true ] && call_script "ssl" "$domain"
                ;;
            -rdns|--rdns|-r)
                [ $is_domain_valid == true ] && call_script "rdns" "$domain"
                ;;
            -whois|--whois|-w)
                [ $is_domain_valid == true ] && call_script "norid" "$domain"
                ;;
            *)
                echo -e "${RED}Error: Unsupported flag $flag.${RESET}"
                ;;
        esac
        shift # Move to the next argument/flag
    done
}

# Call check with all arguments
check "$@"
