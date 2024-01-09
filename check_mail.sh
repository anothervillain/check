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
declare -A email_providers
# Known brands: Global
#email_providers["cPanel or similar (self hosted even)"]=".*domain\.com" # Broken
email_providers["MarkMonitor"]=".*pphosted\.com"
email_providers["Google Workspaces"]=".*\google\.com"
email_providers["Microsoft 365"]=".*outlook\.com"
email_providers["Yahoo Mail"]=".*yahoodns\.net"
email_providers["Cloudflare"]=".*cloudflare\.net|.*mxrecord\.io"
# Known brands: Our brands
email_providers["SYSE"]="tornado\.email|.*tornado\.no"
email_providers["One.com"]="mx1\.pub\.mailpod3-cph3\.one\.com|mx2\.pub\.mailpod3-cph3\.one\.com|mx3\.pub\.mailpod3-cph3\.one\.com"
email_providers["Digital Garden"]="mx1\.pub\.mailpod1-osl1\.one\.com|mx2\.pub\.mailpod1-osl1\.one\.com|mx3\.pub\.mailpod1-osl1\.one\.com"
email_providers["ProISP"]="mx1-pub\.mailmod1-osl1\.one\.com|mx2-pub\.mailmod1-osl1\.one\.com|mx3-pub\.mailmod1-osl1\.one\.com"
# Known Brands: Local
email_providers["Domeneshop"]="*\.domeneshop\.no"
# Disabling case-insensitivity
shopt -u nocasematch

# Function to guess email host based on MX records
guess_email_host() {
    local domain=$1
    local mx_records
    mx_records=$(dig mx "$domain" +short)
    local found=false

    for host in "${!email_providers[@]}"; do
        if echo "$mx_records" | grep -Eiq "${email_providers[$host]}"; then
            echo -e "${GREEN}Going to go with:${RESET}" "${CYAN}$host!${RESET}"
            found=true
            break
        fi
    done

    if [ "$found" = false ]; then
        # Don't display anything if no guess can be made
        return
    fi
}

# Enable case-insensitive pattern matching
shopt -s nocasematch
# Colorize known secondary senders in SPF record
declare -A spf_mass_senderss
# Patterns for secondary senders in SPF records
spf_mass_senderss["ActiveCampaign"]="include:spf.activecampaign.com"
spf_mass_senderss["Amazon SES"]="include:amazonses.com"
spf_mass_senderss["AWeber"]="include:send.aweber.com"
spf_mass_senderss["Campaign Monitor"]="include:_spf.createsend.com"
spf_mass_senderss["Constant Contact"]="include:spf.constantcontact.com"
spf_mass_senderss["GetResponse"]="include:spf.getresponse.com"
spf_mass_senderss["HubSpot"]="include:_spf\.hubspot\.com|include:.*\.hubspotemail\.net"
spf_mass_senderss["Klaviyo"]="include:send.klaviyo.com"
spf_mass_senderss["MailChimp"]="include:spf\.mandrillapp\.com|include:servers\.mcsv\.net"
spf_mass_senderss["MailerLite"]="include:_spf.mailerlite.com"
spf_mass_senderss["Mailgun"]="include:mailgun.org"
spf_mass_senderss["Mandrill"]="include:spf.mandrillapp.com"
spf_mass_senderss["Mimecast"]="include:_netblocks.mimecast.com"
spf_mass_senderss["Moosend"]="include:spf.moosend.com"
spf_mass_senderss["Postmark"]="include:spf.mtasv.net"
spf_mass_senderss["Rackspace"]="include:emailsrvr.com"
spf_mass_senderss["Salesforce"]="include:_spf.salesforce.com"
spf_mass_senderss["SendGrid"]="include:sendgrid.net"
spf_mass_senderss["SendinBlue"]="include:spf.sendinblue.com"
spf_mass_senderss["Zendesk"]="include:mail\.zendesk\.com|include:smtp\.zendesk\.com"
spf_mass_senderss["Zoho"]="include:zoho.eu"

# Disabling  case-sensitivity again
shopt -u nocasematch

# Patterns for known brand senders in SPF records
declare -A spf_known_hosts
spf_known_hosts["SYSE"]="include:tornado.email"
spf_known_hosts["Uniweb"]="_spf.uniweb.no"
spf_known_hosts["Fastname"]="_spf.fastname.no"
spf_known_hosts["ProISP"]="_spf.proisp.no"
spf_known_hosts["Google"]="_spf.google.com"
spf_known_hosts["Microsoft"]="spf.protection.outlook.com"

# Function to check and colorize primary and secondary senders in SPF
check_secondary_senders() {
    local domain=$1
    local spf_record=$(dig +short txt $domain | grep 'v=spf1' | tr -d '"')
    local colored_spf_record=""

    if [ -z "$spf_record" ]; then
        echo -e "${RED}No SPF record found for $domain${RESET}"
        return
    fi

    for part in $spf_record; do
        local match_found=false
        # Check for known primary SPF records
        for primary_sender in "${!spf_known_hosts[@]}"; do
            if [[ "$part" =~ ${spf_known_hosts[$primary_sender]} ]]; then
                colored_spf_record+="${CYAN}$part${RESET} "  # CYAN or another color for primary SPF
                match_found=true
                break
            fi
        done
        # Check for secondary senders if not a primary sender
        if [ "$match_found" = false ]; then
            for sender in "${!spf_mass_senderss[@]}"; do
                if [[ "$part" =~ ${spf_mass_senderss[$sender]} ]]; then
                    colored_spf_record+="${MAGENTA}$part${RESET} "
                    match_found=true
                    break
                fi
            done
        fi
        # Default coloring for other parts
        if [ "$match_found" = false ]; then
            if [[ "$part" =~ (all|~all|-all|\?all)$ ]]; then
                colored_spf_record+="${BLUE}$part${RESET} "
            else
                colored_spf_record+="${GREEN}$part${RESET} "
            fi
        fi
    done

    echo -e "${colored_spf_record}"
}

echo -e "${MAGENTA}------------------------------------------${RESET}"
echo -e "${YELLOW}${1^^} EMAIL RELEVANT INFORMATION${RESET}"
echo -e "${MAGENTA}------------------------------------------${RESET}"

# MX RECORD(S)
mx_result=$(dig mx "$1" +short)
if [ -n "$mx_result" ]; then
    echo -e "${YELLOW}MX RECORD(S)${RESET}"
    echo -e "${GREEN}$mx_result${RESET}"
fi

echo -e "${YELLOW}SPF RECORD${RESET}"
# Logic found further up "check_secondary senders"
check_secondary_senders "$1"

# DMARC RECORD Check
dmarc_result=$(dig +short txt "_dmarc.$1")
if [ -n "$dmarc_result" ]; then
    echo -e "${YELLOW}DMARC RECORD${RESET}"
    echo -e "${GREEN}$dmarc_result${RESET}"
fi

# DKIM RECORD Check
dkim_results=$(dig +short txt "$1" | grep 'v=DKIM1')
if [ -n "$dkim_results" ]; then
    echo -e "${YELLOW}DKIM RECORD(S)${RESET}"
    echo "$dkim_results" | while read -r dkim_record; do
        echo -e "${GREEN}$dkim_record${RESET}"
    done
fi

# Guess email based on MX records
email_guess=$(guess_email_host "$1")
if [ -n "$email_guess" ]; then
    echo -e "${YELLOW}EMAIL GUESSER${RESET}"
    echo -e "$email_guess"
fi
