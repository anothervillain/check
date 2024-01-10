#!/bin/bash

# ANSI color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
CYAN="\033[0;36m"
RESET="\033[0m"

# Function to use registrarwhois (norid)
function whs() {
    domain_name="$1"
    if [ -z "$domain_name" ]; then
        echo -e "${YELLOW}Usage: whs domain_name${RESET}"
        return 1
    fi
    whois_output=$(whois -h registrarwhois.norid.no "$domain_name")
    # Using awk to format and color the output
    echo "$whois_output" | LC_ALL=en_US.UTF-8 awk -v red="$RED" -v green="$GREEN" -v blue="$BLUE" -v yellow="$YELLOW" -v magenta="$MAGENTA" -v cyan="$CYAN" -v reset="$RESET" -v registrarResult="$registrar_result" '
    BEGIN { found = 0; printCreatedUpdated = 0; created = ""; lastUpdated = ""; additionalPrinted = 0; noridPrinted = 0; regPrinted = 0; } 

    /Domain Information/ { found = 1; next }
found && /Created:/ {
    if (printCreatedUpdated == 0) {
        created = $0;
        next;
    }
}
found && /Last updated:/ {
    if (printCreatedUpdated == 0) {
        lastUpdated = $0;
        printCreatedUpdated = 1;
        next;
    }
}
found && /Additional information:/ {
    if (additionalPrinted == 0) {
        additionalPrinted = 0;
        next;
    }
}
found && /NORID Handle/ {
    if (noridPrinted == 0) {
        noridPrinted = 1;
    } else {
        next;
    }
}
found && /Registrar Handle/ {
    if (regPrinted == 0) {
        regPrinted = 1;
    } else {
        next;
    }
}
found && !/Id Type|Organization Type|Type|Post Address|Postal Code|Postal Area|Country|Created:|Last updated:/ {
    sub(/^[ \t]+/, "", $0) # Trim leading whitespace
    sub(/[ \t]+$/, "", $0) # Trim trailing whitespace
    if ($0 != "") { # Only process non-empty lines
        split($0, parts, ":") # Split line into parts by colon
        key = parts[1];
        value = substr($0, length(parts[1]) + 2); # Extract the value
        gsub(/^[ \t]+/, "", value) # Trim whitespace from the value
        
        {
            color = green;
            if (key ~ /NORID Handle|Domain Name|Domain Holder Handle/) color = blue;
            if (key ~ /Name Server Handle/) color = cyan;
            if (key ~ /Registrar Handle|Tech-c Handle/) color = yellow;
            if (key ~ /Organization Name|Id Number/) color = magenta;
        }

        printf blue "%-30s" reset, parts[1] ":" # Print the field name in blue
        printf color "%s" reset, value # Print the value in the specified color
        printf "\n"
    }
}
END {
    if (created != "") {
        printf "\n"
        printf green created reset "\n";
    }
    if (lastUpdated != "") {
        printf green lastUpdated reset "\n";
    }
}'
}

whs "$1"