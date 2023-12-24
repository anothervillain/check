import subprocess
import sys
from tabulate import tabulate
import colorama
import threading
import time

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
            # Return PTR record with colored record type and IP version
            return f"{GREEN}PTR{RESET} {YELLOW}({record_type}){RESET}", ptr_records[0]
        elif soa_record:
            soa_content = soa_record.split("SOA")[-1].strip()
            last_period_index = soa_content.rfind('.')
            soa_content_truncated = soa_content[:last_period_index + 1] if last_period_index != -1 else soa_content
            # Return SOA record with colored record type and IP version
            return f"{RED}SOA{RESET} {YELLOW}({record_type}){RESET}", soa_content_truncated
        return "NONE", f"No PTR or SOA record found for {ip_address}"
    except subprocess.CalledProcessError as e:
        return "ERROR", f"Lookup failed for {ip_address}: {e}"

# Function to display a loading animation
def loading_animation():
    animation = "|/-\\"
    for _ in range(10):
        for frame in animation:
            sys.stdout.write('\r' + YELLOW + 'Loading results...' + frame + RESET)
            sys.stdout.flush()
            time.sleep(0.1)

# Function to perform reverse DNS lookup with loading animation
def reverse_dns_lookup(domain):
    # Start loading animation in a separate thread
    animation_thread = threading.Thread(target=loading_animation)
    animation_thread.start()

    # Execute dig command to find A and AAAA records
    try:
        a_records = subprocess.check_output(["dig", domain, "A", "+short"], text=True).strip().split('\n')
        aaaa_records = subprocess.check_output(["dig", domain, "AAAA", "+short"], text=True).strip().split('\n')

        # Store results for tabulated output
        lookup_results = []

        for record_type, ip_list in (('A', a_records), ('AAAA', aaaa_records)):
            for ip in ip_list:
                if ip:
                    record_type_result, result = dig_reverse_dns_lookup(ip, record_type)
                    # Append results with record type and IP version
                    lookup_results.append((record_type_result, f"{CYAN}{ip}{RESET}", f"{GREEN}{result}{RESET}"))

        # Output the results in a tabulated format
        headers = [f"{YELLOW}RECORD{RESET}", f"{YELLOW}IP ADDRESS{RESET}", f"{YELLOW}RESULT{RESET}"]
        # Stop the loading animation
        animation_thread.join()
        print('\r' + ' ' * 40)  # Clear the loading animation line
        # Print header for reverse DNS lookup process
        print(f"{YELLOW}REVERSE DNS LOOKUP FOR {domain}:{RESET}")
        print(tabulate(lookup_results, headers=headers, tablefmt='grid'))

    except subprocess.CalledProcessError as e:
        # Stop the loading animation
        animation_thread.join()
        print('\r' + ' ' * 40)  # Clear the loading animation line
        print(f"{RED}Error executing dig command: {e}{RESET}")

# Function to print help information about PTR and SOA records
def print_help_info():
    print(f"{YELLOW}Usage:{RESET} {GREEN}rdns <domain.tld>{RESET} to reverse DNS lookup all A & AAAA records.")
    print(f"{YELLOW}Why is this information relevant?{RESET}")
    print(f"{GREEN}PTR{RESET} will tell you what server the IP's respond to. {CYAN}This is the host!{RESET}")
    print(f"{RED}SOA{RESET} will tell you the Start of Authority for the domain, but not necessarily the host.")

# Main execution point
if __name__ == "__main__":
    # Command line argument handling
    if len(sys.argv) < 2:
        print(f"{YELLOW}Usage: python rdns.py <DOMAIN.TLD>{RESET}")
        print(f"{YELLOW}For more information, type: python rdns.py -help{RESET}")
    elif sys.argv[1] in ['-h', '--help', '-help']:
        print_help_info()  # Call the function to print help information
    else:
        reverse_dns_lookup(sys.argv[1].upper())
