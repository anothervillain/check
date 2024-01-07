#!/bin/bash

# ANSI color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
CYAN="\033[0;36m"
RESET="\033[0m"

# Define known patterns for common email hosting services
declare -A email_host_patterns
email_host_patterns["cPanel or smth"]="*$1"
email_host_patterns["MarkMonitor"]="*.pphosted.com"
email_host_patterns["Google Workspaces"]=".*google.com|*.GOOGLE.COM"
email_host_patterns["Microsoft 365"]=".*outlook.com"
email_host_patterns["Yahoo Mail"]=".*yahoodns.net"
email_host_patterns["Cloudflare"]="*cloudflare.net|*mxrecord.io"
email_host_patterns["One.com"]="mx1.pub.mailpod3-cph3.one.com|mx2.pub.mailpod3-cph3.one.com|mx3.pub.mailpod3-cph3.one.com|*one.com"
email_host_patterns["SYSE"]="tornado.email|*tornado.no"
email_host_patterns["Digital Garden"]="mx1.pub.mailpod1-osl1.one.com|mx2.pub.mailpod1-osl1.one.com|mx3.pub.mailpod1-osl1.one.com|*.uniweb.no|*.fastname.no"
email_host_patterns["ProISP"]="mx1-pub.mailmod1-osl1.one.com|mx2-pub.mailmod1-osl1.one.com|mx3-pub.mailmod1-osl1.one.com"

# Function to guess email host based on MX records
guess_email_host() {
    local domain=$1
    local mx_records
    mx_records=$(dig mx "$domain" +short)

    for host in "${!email_host_patterns[@]}"; do
        if echo "$mx_records" | grep -Eq "${email_host_patterns[$host]}"; then
            echo -e "${GREEN} likely:${RESET}" "${CYAN}$host!${RESET}"
            return
        fi
    done
    echo -e "${RED}Unable to determine the email host for $domain.${RESET}"
}

echo -e "${MAGENTA}------------------------------------------${RESET}"
echo -e "${YELLOW}${1^^} EMAIL RELEVANT INFORMATION${RESET}"
echo -e "${MAGENTA}------------------------------------------${RESET}"

# MX RECORD(S)
echo -e "${YELLOW}MX RECORD(S)${RESET}" "${BLUE}< Mail Server${RESET}"
mx_result=$(dig mx "$1" +short)
if [ -z "$mx_result" ]; then
    echo -e "${RED}No MX record found for $1${RESET}"
else
    echo -e "${GREEN}$mx_result${RESET}"
fi

# SPF RECORD
echo -e "${YELLOW}SPF RECORD${RESET}" "${BLUE}< Sender Policy Framework${RESET}"
spf_result=$(dig +short txt "$1" | grep 'v=spf')
if [ -z "$spf_result" ]; then
    echo -e "${RED}No SPF record found for $1${RESET}"
else
    echo -e "${GREEN}$spf_result${RESET}"
fi

# DMARC RECORD Check
dmarc_result=$(dig +short txt "_dmarc.$1")
if [ -n "$dmarc_result" ]; then
    echo -e "${YELLOW}DMARC RECORD${RESET}" "${BLUE}< DNS based authentication${RESET}"
    echo -e "${GREEN}$dmarc_result${RESET}"
fi

# DKIM RECORD Check
dkim_results=$(dig +short txt "$1" | grep 'v=DKIM1')
if [ -n "$dkim_results" ]; then
    echo -e "${YELLOW}DKIM RECORD(S)${RESET}" "${BLUE}< DomainKeys Identified Mail${RESET}"
    echo "$dkim_results" | while read -r dkim_record; do
        echo -e "${GREEN}$dkim_record${RESET}"
    done
fi

# Print the header
echo -e "${YELLOW}EMAIL GUESSER${RESET}"

# Use a subshell to get colored "Rolling the dice" and concatenate with guess_email_host output
echo -e "$(echo -e "(Rolling the dice)" | lolcat)${GREEN}$(guess_email_host "$1")${RESET}"
