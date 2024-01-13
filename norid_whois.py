# norid_whois.py
import subprocess
import sys
import re
from tabulate import tabulate
from colorama import Fore, init

# Initialize colorama
init(autoreset=True)

def execute_norid_whois(domain_name):
    try:
        result = subprocess.check_output(['whois', '-h', 'registrarwhois.norid.no', domain_name], text=True, encoding='ISO-8859-1')
        return result
    except subprocess.CalledProcessError as e:
        print(f"Failed to execute whois: {e}")
        return None
    except UnicodeDecodeError as e:
        print(f"Unicode decode error: {e}")
        return None

def clean_field_name(field):
    return re.sub(r'\.+$', '', field).strip()

def colorize_value(key, value):
    # Define color mappings for different fields
    color_mappings = {
        "NORID Handle": Fore.YELLOW, 
        "Domain Name": Fore.YELLOW, 
        "Domain Holder Handle": Fore.YELLOW, 
        "Tech-c Handle": Fore.CYAN, 
        "Name Server Handle": Fore.CYAN, 
        "Registrar Handle": Fore.CYAN, 
        "Type": Fore.BLUE, 
        "Name": Fore.BLUE, 
        "Organization Name": Fore.BLUE, 
        "Id Type": Fore.BLUE, 
        "Id Number": Fore.BLUE, 
        "Organization Type": Fore.BLUE
    }
    return f"{color_mappings.get(key, Fore.RESET)}{value}{Fore.RESET}"

def parse_norid_whois_output(whois_output):
    main_data = []
    additional_data = []
    seen_keys = set()
    created_last_updated_count = 0

    for line in whois_output.splitlines():
        line = line.strip()
        if line and ':' in line and not line.startswith('%'):
            key, value = [part.strip() for part in line.split(':', 1)]
            cleaned_key = clean_field_name(key)
            if cleaned_key in ["Additional information", "Post Address", "Postal Code", "Postal Area", "Country"]:
                continue
            colored_value = colorize_value(cleaned_key, value)
            colored_key = f"{Fore.MAGENTA}{cleaned_key}{Fore.RESET}"
            
            if cleaned_key in ["Created", "Last updated"]:
                created_last_updated_count += 1
                if created_last_updated_count > 2:
                    additional_data.append((colored_key, colored_value))
                    continue

            if cleaned_key not in seen_keys:
                main_data.append((colored_key, colored_value))
                seen_keys.add(cleaned_key)

    return main_data + additional_data

def main():
    if len(sys.argv) < 2:
        print("Usage: norid_whois.py domain_name")
        sys.exit(1)

    domain_name = sys.argv[1]
    whois_output = execute_norid_whois(domain_name)
    if whois_output:
        parsed_data = parse_norid_whois_output(whois_output)
        headers = [f"{Fore.YELLOW}Field{Fore.RESET}", f"{Fore.YELLOW}Value{Fore.RESET}"]
        print(tabulate(parsed_data, headers=headers, tablefmt='grid'))
    else:
        print("No output from whois command")

if __name__ == "__main__":
    main()
