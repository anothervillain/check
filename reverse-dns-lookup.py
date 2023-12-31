import subprocess
import os

# ANSI color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
CYAN="\033[0;36m"
RESET="\033[0m"

def dig_reverse_dns_lookup(ip_address, record_type):
    try:
        # Using dig command for detailed reverse DNS lookup
        result = subprocess.check_output(["dig", "-x", ip_address, "+noall", "+answer", "+authority"], text=True).strip()
        if result:
            # Check for PTR records
            ptr_records = [line.split('PTR')[-1].strip() for line in result.splitlines() if "PTR" in line]
            if ptr_records:
                # Return PTR record(s) content
                return "PTR", f"{GREEN}{' '.join(ptr_records)}{RESET} ({YELLOW}{record_type}{RESET})"
            else:
                # Check for SOA record if no PTR record is found
                soa_record = next((line for line in result.splitlines() if "SOA" in line), None)
                if soa_record:
                    # Extract SOA content and truncate at the final period
                    soa_content = soa_record.split("SOA")[-1].strip()
                    last_period_index = soa_content.rfind('.')
                    soa_content_truncated = soa_content[:last_period_index + 1] if last_period_index != -1 else soa_content
                    # Append the record type to the SOA record
                    soa_content_truncated += f" ({record_type})"
                    return "SOA", f"{GREEN}{soa_content_truncated}{RESET}"
        return "NONE", f"{RED}No PTR or SOA record found for {ip_address}{RESET}"
    except subprocess.CalledProcessError as e:
        return "ERROR", f"{RED}Lookup failed for {ip_address}: {e}{RESET}"

# Global flag to ensure messages are printed only once
soa_message_printed = False
header_printed = False

# Print only relevant information based on finds
def print_relevant_answers(ip_addresses, record_type, domain):
    global soa_message_printed, header_printed
    ptr_records = []
    soa_records = set()

    for ip in ip_addresses:
        record_type_found, result = dig_reverse_dns_lookup(ip, record_type)
        if record_type_found == "PTR":
            ptr_records.append(result)
        elif record_type_found == "SOA":
            soa_records.add(result)

    if (ptr_records or soa_records) and not header_printed:
        print(f"{YELLOW}REVERSE DNS LOOKUP{RESET}")
        header_printed = True

    for record in ptr_records:
        print(record)

    if soa_records and not soa_message_printed:
        print(f"{RED}No PTR found, Start of Authority for {domain} is{RESET}")
        for record in soa_records:
            print(record)
        print(f"{CYAN}Tip: You can try using this command: {RESET}{YELLOW}rdns {domain}{RESET}")
        soa_message_printed = True

# Load domain from the file created by the .zsh script
domain = "Unknown"  # Default value in case file does not exist
if os.path.exists('current_domain.txt'):
    with open('current_domain.txt', 'r') as file:
        domain = file.read().strip()

# Load and process A and AAAA results
a_results, aaaa_results = [], []
if os.path.exists('a_results.txt') and os.path.getsize('a_results.txt') > 0:
    with open('a_results.txt') as file:
        a_results = [line.strip() for line in file if line.strip()]

if os.path.exists('aaaa_results.txt') and os.path.getsize('aaaa_results.txt') > 0:
    with open('aaaa_results.txt') as file:
        aaaa_results = [line.strip() for line in file if line.strip()]

# Function to perform a basic dig -x lookup
def basic_dig_reverse_dns(domain):
    try:
        # Fetch the first IP address for the domain
        ip_address = subprocess.check_output(["dig", domain, "+short"], text=True).strip().split('\n')[0]
        if ip_address:
            # Perform a reverse DNS lookup on the first IP address
            reverse_dns_result = subprocess.check_output(["dig", "-x", ip_address, "+short"], text=True).strip()
            if reverse_dns_result:
                return reverse_dns_result
            else:
                return f"{RED}No result found for {domain}{RESET}"
        else:
            return f"{RED}No IP address found for {domain}{RESET}"
    except subprocess.CalledProcessError as e:
        return f"{RED}Lookup failed: {e}{RESET}"

# Perform reverse DNS lookup and print results
if a_results:
    print_relevant_answers(a_results, "A", domain)

if aaaa_results:
    print_relevant_answers(aaaa_results, "AAAA", domain)

# Check if any results were found, if not, do a basic dig -x lookup
if not (a_results or aaaa_results or soa_message_printed or header_printed):
    basic_result = basic_dig_reverse_dns(domain)
    print(f"{YELLOW}REVERSE DNS LOOKUP (Trying dig -x as a last ditch resort){RESET}\n{basic_result}")
