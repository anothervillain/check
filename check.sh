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
source check_help.sh

# Function to check if the domain exists and is not in quarantine
check_domain() {
    local domain=$1
    # Check for invalid domain format
    if echo "$domain" | grep -q '\.\.'; then
        echo -e "${RED}Invalid domain format, fat fingers?!${RESET}"
        return 1
    fi
    # Check domain existence and quarantine status
    local domain_status="$(dig +short A "$domain")"
    local whois_status="$(whois "$domain")" | grep -q 'No match';
    if [[ -z "$domain_status" ]]; then
        echo -e "${RED}NXDOMAIN: The domain $domain does not exist.${RESET}"
        echo -e "${GREEN}Ensure you wrote $domain correctly!${RESET}"
        return 1
    elif echo "$whois_status" | grep -q 'No match'; then
        echo -e "${YELLOW}Domain${RESET}" "${BLUE}$domain${RESET}" "${YELLOW}is in quarantine.${RESET}"
        return 1
    else
        echo -e "${YELLOW}Valid:${RESET}" "${GREEN}Domain $domain looks like it exists.${RESET}"
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
        esac
        shift # Move to the next argument/flag
    done
}

# REGISTRAR Extraction
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
        echo -e "${YELLOW}Registrar:${RESET} ${GREEN}$registrar_result${RESET}"
    else
        echo -e "${RED}No Registrar information found for $domain${RESET}"
        echo -e "${YELLOW}Perform${RESET} whois $domain ${YELLOW}instead!${RESET}"
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

# Function to check if the last run can be skipped
can_skip_checks() {
    local domain=$1
    local time_frame=300 # 5 minutes in seconds

    if [[ -f "$tmp_file" ]]; then
        read -r last_domain last_time < "$tmp_file"
        local current_time=$(date +%s)
        if [[ "$last_domain" == "$domain" && $((current_time - last_time)) -lt $time_frame ]]; then
            return 0 # 0 means yes, can skip
        fi
    fi
    return 1 # 1 means no, cannot skip
}

check() {
    local domain=$1
    local skip_checks=false
    # Check if only flags are provided and if we can skip checks
    if [[ $# -gt 1 && $(can_skip_checks "$domain") -eq 0 ]]; then
        skip_checks=true
    fi
    if [[ -z "$domain" ]]; then
        # [Your existing introduction code]
        echo -e "${MAGENTA}Version: check.sh v.0.1.152b!${RESET}"
        echo -e "${GREEN}This tool quickly checks up on a domain's relevant information${RESET}"
        echo -e "For detailed help, please use: ${YELLOW}check -help${RESET}"
    elif [[ "$domain" == "-help" ]]; then
        show_help
        return
    elif ! $skip_checks; then
        # Perform domain existence and registrar checks
        echo -e "${MAGENTA}------------------------------------------${RESET}"
        echo -e "${YELLOW}${1^^} REGISTRATION INFORMATION${RESET}"
        echo -e "${MAGENTA}------------------------------------------${RESET}"
        check_domain "$domain" && check_registrar "$domain"
        record_last_run "$domain"
    fi
    # Move past the domain argument to process flags
    shift
    while (( "$#" )); do
        case "$1" in
            -all)
                # Call each script with the domain
                call_script "host" "$domain"
                call_script "mail" "$domain"
                ;;
            -host | -mail | -rdns | -ssl | -cert)
                local flag="${1#-}"
                call_script "$flag" "$domain"
                ;;
            *)
                echo -e "${RED}Error:${RESET} Unsupported flag $1" >&2
                return 1
                ;;
        esac
        shift # Move to the next argument/flag
    done
}

# Start the script
check "$@"