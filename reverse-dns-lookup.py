import subprocess
import os

# ANSI color codes
RED = "\033[0;31m"
GREEN = "\033[0;32m"
YELLOW = "\033[0;33m"
RESET = "\033[0m"

def dig_reverse_dns_lookup(ip_address):
    try:
        # Using dig command for detailed reverse DNS lookup
        result = subprocess.check_output(["dig", "-x", ip_address, "+noall", "+answer", "+authority"], text=True).strip()
        if result:
            # Check for PTR records
            ptr_records = [line.split('PTR')[-1].strip() for line in result.splitlines() if "PTR" in line]
            if ptr_records:
                # Return PTR record(s) content
                return f"{GREEN}{' '.join(ptr_records)}{RESET}"
            else:
                # Check for SOA record if no PTR record is found
                soa_record = next((line for line in result.splitlines() if "SOA" in line), None)
                if soa_record:
                    # Extract SOA content and truncate at the final period
                    soa_content = soa_record.split("SOA")[-1].strip()
                    last_period_index = soa_content.rfind('.')
                    if last_period_index != -1:
                        return f"{GREEN}{soa_content[:last_period_index + 1]}{RESET}"
                    else:
                        return f"{GREEN}{soa_content}{RESET}"
        return f"{RED}No PTR or SOA record found for {ip_address}{RESET}"
    except subprocess.CalledProcessError as e:
        return f"{RED}Lookup failed for {ip_address}: {e}{RESET}"

def print_relevant_answers(ip_addresses, record_type, domain):
    for ip in ip_addresses:
        result = dig_reverse_dns_lookup(ip)
        print(f"{result} ({YELLOW}{record_type}{RESET})")

# Load domain from the file created by the .zsh script
if os.path.exists('current_domain.txt'):
    with open('current_domain.txt', 'r') as file:
        domain = file.read(). strip()
else:
    domain = "Unknown"  # Default value in case file does not exist

# Load and process A and AAAA results
a_results, aaaa_results = [], []

if os.path.exists('a_results.txt') and os.path.getsize('a_results.txt') > 0:
    with open('a_results.txt') as file:
        a_results = [line.strip() for line in file if line.strip()]

if os.path.exists('aaaa_results.txt') and os.path.getsize('aaaa_results.txt') > 0:
    with open('aaaa_results.txt') as file:
        aaaa_results = [line.strip() for line in file if line.strip()]

# Perform reverse DNS lookup and print results
if a_results:
    print_relevant_answers(a_results, "A", domain)

if aaaa_results:
    print_relevant_answers(aaaa_results, "AAAA", domain)
