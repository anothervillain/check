import subprocess
import os
import colorama

# Initialize colorama
colorama.init(autoreset=True)

# Define ANSI color codes using colorama
RED = colorama.Fore.RED
BLUE = colorama.Fore.BLUE
GREEN = colorama.Fore.GREEN
YELLOW = colorama.Fore.YELLOW
MAGENTA = colorama.Fore.MAGENTA
PINK = colorama.Fore.LIGHTRED_EX
CYAN = colorama.Fore.CYAN
RESET = colorama.Style.RESET_ALL

def dig_reverse_dns_lookup(ip_address, record_type):
    try:
        # Perform reverse DNS lookup using dig command
        result = subprocess.check_output(["dig", "-x", ip_address, "+noall", "+answer", "+authority"], text=True).strip()
        if result:
            # Check for PTR records in the result
            ptr_records = [line.split('PTR')[-1].strip() for line in result.splitlines() if "PTR" in line]
            if ptr_records:
                # Return PTR record(s) content and True indicating PTR record found
                return True, f"{GREEN}{' '.join(ptr_records)}{RESET} ({YELLOW}{record_type}{RESET})"
            # No PTR records found, check for SOA records
            soa_records = [line.split('SOA')[-1].strip() for line in result.splitlines() if "SOA" in line]
            if soa_records:
                # Truncate SOA record(s) content at the final period
                soa_content_truncated = soa_records[0].rsplit('.', 1)[0] + '.'
                # Return SOA record(s) content in MAGENTA color and False indicating PTR record not found
                return False, f"{MAGENTA}{soa_content_truncated}{RESET}"
            # Neither PTR nor SOA records found
            return False, ""
        # No result from dig command
        return False, ""
    except subprocess.CalledProcessError as e:
        # Handle errors from the subprocess call
        return False, ""

# Global flags to ensure messages are printed only once
soa_message_printed = False
header_printed = False

def print_relevant_answers(ip_addresses, record_type, domain):
    global soa_message_printed, header_printed
    if not header_printed:
        print(f"{YELLOW}REVERSE DNS LOOKUP{RESET} {CYAN}* PTR or SOA{RESET}")
        header_printed = True

    ptr_found_any = False
    for ip in ip_addresses:
        # Perform reverse DNS lookup for each IP address
        ptr_found, lookup_result = dig_reverse_dns_lookup(ip, record_type)
        if ptr_found:
            # Print the PTR record if found
            print(lookup_result)
            ptr_found_any = True

    if not ptr_found_any and not soa_message_printed:
        print(f"{lookup_result} {RED}(SOA){RESET}")
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
