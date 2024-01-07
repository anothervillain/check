#!/bin/bash

# ANSI color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
CYAN="\033[0;36m"
RESET="\033[0m"

# Connect to a hostname using openssl to show complete certificate chain.
check-ssl() {
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

    # SSL CERTIFICATE
    echo -e "${YELLOW}${1^^} SSL CERTIFICATE${RESET}"
    check_ssl_certificate "$1"
