# Python script for reverse DNS lookup with enhanced output

import subprocess
import re

# ANSI color codes
RED = "\033[0;31m"
GREEN = "\033[0;32m"
YELLOW = "\033[0;33m"
RESET = "\033[0m"

def dig_reverse_dns_lookup(ip_address):
    try:
        result = subprocess.check_output(["dig", "-x", ip_address, "+noall", "+answer", "+authority"], text=True).strip()
        ptr_records = [line.split('PTR')[-1].strip() for line in result.splitlines() if "PTR" in line]
        if ptr_records:
            return "PTR", f"{GREEN}{' '.join(ptr_records)}{RESET}"
        else:
            soa_record = next((line for line in result.splitlines() if "SOA" in line), None)
            if soa_record:
                soa_content = soa_record.split("SOA")[-1].strip()
                last_period_index = soa_content.rfind('.')
                soa_content_truncated = soa_content[:last_period_index + 1] if last_period_index != -1 else soa_content
                return "SOA", f"{GREEN}{soa_content_truncated}{RESET}"
        return "NONE", f"{RED}No PTR or SOA record found for {ip_address}{RESET}"
    except subprocess.CalledProcessError as e:
        return "ERROR", f"{RED}Lookup failed for {ip_address}: {e}{RESET}"

def reverse_dns_lookup(domain):
    try:
        # Fetch A and AAAA records for the domain
        a_records = subprocess.check_output(["dig", domain, "A", "+short"], text=True).strip().split('\n')
        aaaa_records = subprocess.check_output(["dig", domain, "AAAA", "+short"], text=True).strip().split('\n')

        # Check if A records exist
        if not a_records or not a_records[0]:
            print(f"{RED}Nope. Try again maybe? :){RESET}")
            return

        # Process and print results for A records
        for ip in a_records:
            print(f"{YELLOW}A RECORD: {GREEN}{ip}{RESET}")
            record_type_found, result = dig_reverse_dns_lookup(ip)
            print(f"{YELLOW}RESULT: {result}")

        # Process and print results for AAAA records
        for ip in aaaa_records:
            print(f"{YELLOW}AAAA RECORD: {GREEN}{ip}{RESET}")
            record_type_found, result = dig_reverse_dns_lookup(ip)
            print(f"{YELLOW}RESULT: {result}")

    except subprocess.CalledProcessError as e:
        print(f"{RED}Error executing dig command: {e}{RESET}")

if __name__ == "__main__":
    import sys
    if len(sys.argv) < 2:
        print(f"{RED}Usage: python reverse_dns_lookup.py <domain.tld>{RESET}")
    else:
        reverse_dns_lookup(sys.argv[1])
