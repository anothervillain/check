import subprocess
import sys
from tabulate import tabulate
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
            # Return PTR record with colored record type
            return f"{GREEN}PTR{RESET} {YELLOW}({record_type}){RESET}", ptr_records[0]
        elif soa_record:
            soa_content = soa_record.split("SOA")[-1].strip()
            last_period_index = soa_content.rfind('.')
            soa_content_truncated = soa_content[:last_period_index + 1] if last_period_index != -1 else soa_content
            # Return SOA record with colored record type
            return f"{RED}SOA{RESET} {YELLOW}({record_type}){RESET}", soa_content_truncated
        return "NONE", f"No PTR or SOA record found for {ip_address}"
    except subprocess.CalledProcessError as e:
        return "ERROR", f"Lookup failed for {ip_address}: {e}"

# Function to validate the domain using WHOIS
def is_valid_domain(domain):
    # Adjust the domain validation to support subdomains
    domain_parts = domain.split('.')
    if len(domain_parts) < 2:
        return False
    # Consider the last two parts of the domain for validation
    main_domain = '.'.join(domain_parts[-2:])
    try:
        # Execute whois command to check domain validity
        whois_output = subprocess.check_output(["whois", main_domain], text=True, stderr=subprocess.STDOUT)
        # Check for specific strings in the whois output that indicate a valid domain
        if "No match for domain" in whois_output or "No entries found" in whois_output:
            return False
        return True
    except subprocess.CalledProcessError:
        return False

# Function to check if the input is a subdomain
def is_subdomain(domain):
    """
    Check if the given domain is a subdomain.
    """
    return len(domain.split('.')) > 2

# Function to perform reverse DNS lookup with domain validation
def reverse_dns_lookup(domain):
    # Validate the domain format
    if not is_valid_domain(domain):
        print(f"{RED}The domain is not properly formatted or its NXDOMAIN.{RESET}")
        return

    try:
        # Obtain A and AAAA records for the domain
        a_records_output = subprocess.check_output(["dig", domain, "+short", "A"], text=True).strip()
        aaaa_records_output = subprocess.check_output(["dig", domain, "+short", "AAAA"], text=True).strip()

        # Split the output into a list of IP addresses
        ip_list = list(set(a_records_output.splitlines() + aaaa_records_output.splitlines())) # Remove duplicates
        lookup_results = []

        for ip in ip_list:
            record_type = "A" if ':' not in ip else "AAAA"
            record_type_result, result = dig_reverse_dns_lookup(ip, record_type)
            # Append results
            lookup_results.append((record_type_result, f"{CYAN}{ip}{RESET}", f"{GREEN}{result}{RESET}"))

        # Output the results in a tabulated format
        headers = [f"{YELLOW}RECORD{RESET}", f"{YELLOW}IP ADDRESS{RESET}", f"{YELLOW}RESULT{RESET}"]

        # Determine header based on whether domain is a subdomain
        header_domain = f"{CYAN}{domain.upper()}{RESET}" if is_subdomain(domain) else f"{CYAN}{domain.upper()}{RESET}"
        # Print header for reverse DNS lookup process
        print(f"{YELLOW}REVERSE DNS LOOKUP FOR {header_domain}:{RESET}")
        print(tabulate(lookup_results, headers=headers, tablefmt='grid'))

    except subprocess.CalledProcessError as e:
        print(f"{RED}Error executing dig: {e}{RESET}")

# Function to print help information about PTR and SOA records in a tabulated format
def print_help_info():
    help_info = [
        (f"{CYAN}INFO{RESET}", "Reverse DNS Lookup lets you see the server your domains IP connects to"),
        (f"{GREEN}PTR{RESET}", "Indicates which server the individual IP (A/AAAA record) connects to."),
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
    else:
        if sys.argv[1] in ['-h', '--help', '-help']:
            print_help_info()  # Inputted domain is not legit
        elif not is_valid_domain(sys.argv[1]):
            print(f"{RED}That doesn't look like a properly formatted domain or its NXDOMAIN.{RESET}")
        else:
            reverse_dns_lookup(sys.argv[1].lower())

