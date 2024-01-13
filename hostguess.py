
import subprocess
import re
import ipaddress
import sys
import colorama

# Initialize colorama
colorama.init(autoreset=True)

# Define ANSI color codes using colorama
RED = colorama.Fore.RED
GREEN = colorama.Fore.GREEN
YELLOW = colorama.Fore.YELLOW
MAGENTA = colorama.Fore.MAGENTA
PINK = colorama.Fore.LIGHTRED_EX
RESET = colorama.Style.RESET_ALL

def is_ip_in_range(ip, ip_range):
    """Check if an IP address is within a given subnet."""
    return ipaddress.ip_address(ip) in ipaddress.ip_network(ip_range)

def perform_whois_lookup(ip_address):
    """Perform a WHOIS lookup and return organization name."""
    try:
        whois_output = subprocess.check_output(["whois", ip_address], text=True)
        org_name_search = re.search(
            r'(org-name|org-name:|OrgName|Organization|Registrant Organization):\s*(.+)',
            whois_output, re.IGNORECASE)
        if org_name_search and "REDACTED FOR PRIVACY" not in org_name_search.group(2):
            return org_name_search.group(2).strip()
    except Exception as e:
        print(f"{RED}Error in WHOIS lookup: {e}{RESET}")
    return None

def run_subprocess(command):
    """Run a subprocess command and return its output."""
    try:
        return subprocess.check_output(command, text=True).strip()
    except subprocess.CalledProcessError as e:
        print(f"{RED}Error running command {command}: {e}{RESET}")
        return None

def host_guesser(domain):
    """Guess the host of a given domain."""
    print(f"{YELLOW}HOST GUESSER{RESET}")
    try:
        # Checking for known hosts through CNAME
        www_cname_result = subprocess.check_output(["dig", "www." + domain, "CNAME", "+short"], text=True).strip()
        # Extract the first available IP adress
        a_result = subprocess.check_output(["dig", "a", domain, "+short"], text=True).strip().split('\n')[0]
        # Perform reverse DNS lookup
        reverse_dns_result = subprocess.check_output(["dig", "-x", a_result, "+short"], text=True).strip()
        # For Digital Garden, we need to check the SOA record, not using +short
        reverse_dns_result = run_subprocess(["dig", "-x", a_result])
        digital_garden_signature = "ns.syse.no. hostmaster.ns.syse.no."
        is_digital_garden = digital_garden_signature in reverse_dns_result
        # If the result is SSL redirect proxy
        if a_result == "104.37.39.71":
            print(f"{GREEN}{a_result}{RESET} (SSL Redirect Proxy or default A record)")
        # KNOWN HOSTS: External website builders
        elif ".squarespace.com" in www_cname_result:
            print(f"{GREEN}Hosted at Squarespace |{RESET} {PINK}www.{domain}{RESET} IN CNAME {MAGENTA}{www_cname_result}{RESET}")
        elif "shopify.com" in www_cname_result:
            print(f"{GREEN}Hosted at Shopify |{RESET} {PINK}www.{domain}{RESET} IN CNAME {MAGENTA}{www_cname_result}{RESET}")
        elif "wixdns.net" in www_cname_result:
            print(f"{GREEN}Hosted at Wix |{RESET} {PINK}www.{domain}{RESET} IN CNAME {MAGENTA}{www_cname_result}{RESET}")
        elif "hostinger.com" in www_cname_result:
            print(f"{GREEN}Hosted at Hostinger |{RESET} {PINK}www.{domain}{RESET} IN CNAME {MAGENTA}{www_cname_result}{RESET}")
        elif "proxy-ssl.webflow.com" in www_cname_result:
            print(f"{GREEN}Hosted at Webflow |{RESET} {PINK}www.{domain}{RESET} IN CNAME {MAGENTA}{www_cname_result}{RESET}")
        # KNOWN HOSTS: Our brands
        elif is_digital_garden:
            print(f"{GREEN}Hosted at Digital Garden!{RESET} {PINK}Detected based on SOA record.{RESET}")
        elif ".tornado-node.net" in reverse_dns_result or ".tornado.no" in reverse_dns_result:
            print(f"{GREEN}Hosted at SYSE!{RESET} {PINK}Guess based on RDNS lookup.{RESET}")
        elif ".proisp.no" in reverse_dns_result:
            print(f"{GREEN}Hosted at (Legacy) ProISP!{RESET} {PINK}Guess based on RDNS lookup.{RESET}")
        elif "webcluster1.webpod1-osl1.one.com" in reverse_dns_result:
            print(f"{GREEN}Hosted at ProISP!{RESET} {PINK}Guess based on RDNS lookup.{RESET}")
            # KNOW HOSTS: Known brands outisde our ecosystem
        elif "domeneshop.no" in reverse_dns_result or "domainname.shop" in reverse_dns_result:
            print(f"{GREEN}Hosted at Domeneshop!{RESET} {PINK}Guess based on RDNS lookup.{RESET}")
        elif ".1e100.net" in reverse_dns_result:
            print(f"{GREEN}Hosted at Google Cloud!{RESET} {PINK}Guess based on RDNS lookup.{RESET}")
        else:
            # Perform WHOIS lookup if no known host is found
            org_name = perform_whois_lookup(a_result)
            if org_name:
                print(f"{MAGENTA}Rolling the dice...{RESET} {GREEN}{org_name}{RESET}")
            else:
                print(f"{RED}Hosting for {domain} could not be determined{RESET}")

    except subprocess.CalledProcessError as e:
        print(f"{RED}Error in host guessing: {e}{RESET}")

# Main logic to accept a command-line argument
if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"{RED}Usage: python3 hostguess.py <domain>{RESET}")
    else:
        domain_to_check = sys.argv[1]
        host_guesser(domain_to_check)
