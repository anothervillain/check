import subprocess
import os

# ANSI color codes
RED = "\033[0;31m"
GREEN = "\033[0;32m"
YELLOW = "\033[0;33m"
BLUE = "\033[0;34m"
RESET = "\033[0m"

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
                    return "SOA", f"{GREEN}{soa_content_truncated}{RESET}"
        return "NONE", f"{RED}No PTR or SOA record found for {ip_address}{RESET}"
    except subprocess.CalledProcessError as e:
        return "ERROR", f"{RED}Lookup failed for {ip_address}: {e}{RESET}"

# Global flag to ensure messages are printed only once
soa_message_printed = False

# Print only relevant information based on finds
def print_relevant_answers(ip_addresses, record_type, domain):
    global soa_message_printed  # Use the global flag
    ptr_records = []
    soa_records = set()

    for ip in ip_addresses:
        record_type_found, result = dig_reverse_dns_lookup(ip, record_type)
        if record_type_found == "PTR":
            ptr_records.append(result)
        elif record_type_found == "SOA":
            soa_records.add(result)

    if ptr_records:
        for record in ptr_records:
            print(record)
    elif soa_records and not soa_message_printed:
        # Print the SOA message only once overall
        print(f"{RED}No PTR found. SOA for {domain} is printed instead{RESET}")
        print(f"{GREEN}You can try using the digx command: digx {domain}{RESET}")
        soa_message_printed = True  # Update the flag after printing
        for record in soa_records:
            print(record)

# Load domain from the file created by the .zsh script
if os.path.exists('current_domain.txt'):
    with open('current_domain.txt', 'r') as file:
        domain = file.read().strip()
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
