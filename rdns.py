import subprocess
import sys
from tabulate import tabulate
import colorama
import re

# Initialize colorama for colored terminal text
colorama.init(autoreset=True)

# Define ANSI color codes
RED = colorama.Fore.RED
GREEN = colorama.Fore.GREEN
YELLOW = colorama.Fore.YELLOW
CYAN = colorama.Fore.CYAN
RESET = colorama.Style.RESET_ALL

# Function to perform reverse DNS lookup using dig
def dig_reverse_dns_lookup(ip_address, record_type):
    if not ip_address:
        return "NONE", ""
    try:
        # Execute dig command for reverse DNS lookup
        result = subprocess.check_output(["dig", "-x", ip_address, "+noall", "+answer", "+authority"], text=True).strip()
        # Parse PTR records from the result
        ptr_records = [line.split('PTR')[-1].strip() for line in result.splitlines() if "PTR" in line]
        # Parse SOA records if PTR records are not found
        soa_record = next((line for line in result.splitlines() if "SOA" in line), None)
        if ptr_records:
            # Return PTR record with colored record type and IP address type (A or AAAA)
            return f"{GREEN}PTR{RESET} {YELLOW}(A){RESET}" if record_type == "IPv4" else f"{GREEN}PTR{RESET} {YELLOW}(AAAA){RESET}", ptr_records[0]
        elif soa_record:
            soa_content = soa_record.split("SOA")[-1].strip()
            last_period_index = soa_content.rfind('.')
            soa_content_truncated = soa_content[:last_period_index + 1] if last_period_index != -1 else soa_content
            # Return SOA record with colored record type and IP address type (A or AAAA)
            return f"{RED}SOA{RESET} {YELLOW}(A){RESET}" if record_type == "IPv4" else f"{RED}SOA{RESET} {YELLOW}(AAAA){RESET}", soa_content_truncated
        return "NONE", f"No PTR or SOA record found for {ip_address}"
    except subprocess.CalledProcessError as e:
        return "ERROR", f"Lookup failed for {ip_address}: {e}"

# Function to validate the domain using WHOIS
def is_valid_domain(domain):
    try:
        # Execute whois command to check domain validity
        subprocess.check_output(["whois", domain], text=True)
        return True
    except subprocess.CalledProcessError:
        return False

# Function to perform reverse DNS lookup with domain validation
def reverse_dns_lookup(domain):
    # Validate the domain format
    if not is_valid_domain(domain):
        print(f"{RED}The domain is not valid or does not exist.{RESET}")
        return

    try:
        # Obtain A and AAAA records for the domain
        a_records_output = subprocess.check_output(["dig", domain, "+short", "A"], text=True).strip()
        aaaa_records_output = subprocess.check_output(["dig", domain, "+short", "AAAA"], text=True).strip()

        # Split the output into a list of IP addresses
        ip_list = a_records_output.splitlines() + aaaa_records_output.splitlines()
        lookup_results = []

        for record_type in ["IPv4", "IPv6"]:
            for ip in ip_list:
                if ip:
                    record_type_label = "A" if record_type == "IPv4" else "AAAA"
                    record_type_result, result = dig_reverse_dns_lookup(ip, record_type)
                    # Append results with record type (A or AAAA)
                    lookup_results.append((record_type_result.replace(record_type, record_type_label), f"{CYAN}{ip}{RESET}", f"{GREEN}{result}{RESET}"))

        # Output the results in a tabulated format
        headers = [f"{YELLOW}RECORD{RESET}", f"{YELLOW}IP ADDRESS{RESET}", f"{YELLOW}RESULT{RESET}"]
        # Print header for reverse DNS lookup process
        print(f"{YELLOW}REVERSE DNS LOOKUP FOR {domain}:{RESET}")
        print(tabulate(lookup_results, headers=headers, tablefmt='grid'))

    except subprocess.CalledProcessError as e:
        print(f"{RED}Error executing dig: {e}{RESET}")

# Function to print help information about PTR and SOA records in a tabulated format
def print_help_info():
    help_info = [
        (f"{CYAN}INFO{RESET}", "Reverse DNS Lookup lets you see the server your domains IP connects to"),
        (f"{GREEN}PTR{RESET}", "Indicates which server the individual IP (A/AAAA record) respond to."),
        (f"{RED}SOA{RESET}", "Shows the Start of Authority for the domain, but not necessarily the host.")
    ]
    print(f"{YELLOW}Usage:{RESET} {GREEN}rdns <domain.tld>{RESET}")
    print(tabulate(help_info, headers=[], tablefmt='grid'))

# Main execution point
if __name__ == "__main__":
    # Command line argument handling
    if len(sys.argv) < 2:
        print(f"{RED}Please provide a domain.{RESET}")
        print_help_info()  # Call the function to print help information
    elif sys.argv[1] in ['-h', '--help', '-help']:
        print_help_info()  # Inputted domain is not legit
    elif not is_valid_domain(sys.argv[1]):
        print(f"{RED}That doesn't look like a properly formatted domain or it does not exist.{RESET}")
    else:
        reverse_dns_lookup(sys.argv[1].lower())
