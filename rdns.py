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
def dig_reverse_dns_lookup(ip_address):
    if not ip_address:
        return "NONE", ""
    try:
        # Execute dig command for reverse DNS lookup
        result = subprocess.check_output(["dig", "-x", ip_address, "+noall", "+answer", "+authority"], text=True).strip()
        # Parse PTR records from the result
        ptr_records = [line.split('PTR')[-1].strip() for line in result.splitlines() if "PTR" in line]
        if ptr_records:
            # Return PTR record with colored record type
            return f"{GREEN}PTR{RESET}", ptr_records[0]
        else:
            # Parse SOA records if PTR records are not found
            soa_record = next((line for line in result.splitlines() if "SOA" in line), None)
            if soa_record:
                soa_content = soa_record.split("SOA")[-1].strip()
                last_period_index = soa_content.rfind('.')
                soa_content_truncated = soa_content[:last_period_index + 1] if last_period_index != -1 else soa_content
                # Return SOA record with colored record type
                return f"{RED}SOA{RESET}", soa_content_truncated
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

        for ip in a_records + aaaa_records:
            if ip:
                record_type_colored, result = dig_reverse_dns_lookup(ip)
                # Append results with colored record type
                lookup_results.append((record_type_colored, f"{CYAN}{ip}{RESET}", f"{GREEN}{result}{RESET}"))

        # Output the results in a tabulated format with capitalized headers
        headers = [f"{YELLOW}RECORD{RESET}", f"{YELLOW}IP ADDRESS{RESET}", f"{YELLOW}RESULT (CHECK TYPE){RESET}"]
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

# Main execution point
if __name__ == "__main__":
    # Command line argument handling
    if len(sys.argv) < 2:
        print(f"{YELLOW}Usage: python rdns.py <DOMAIN.TLD>{RESET}")
    else:
        reverse_dns_lookup(sys.argv[1].upper())
