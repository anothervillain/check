import socket
import json

def store_dns_results(dns_results, filename):
    # Save DNS results to a file in JSON format
    with open(filename, 'w') as file:
        json.dump(dns_results, file)

def load_dns_results(filename):
    # Load DNS results from a file
    with open(filename) as file:
        return json.load(file)

def reverse_dns_lookup(ip_addresses):
    # Perform reverse DNS lookup for a list of IP addresses
    reverse_results = {}
    for ip in ip_addresses:
        try:
            # Get the hostname associated with the IP address
            hostname = socket.gethostbyaddr(ip)[0]
            reverse_results[ip] = hostname
        except Exception as e:
            # If reverse lookup fails, store the error message
            reverse_results[ip] = f"Lookup failed: {e}"
    return reverse_results

def print_relevant_answers(reverse_results):
    # Print the most relevant answers from reverse DNS lookup results
    for ip, hostname in reverse_results.items():
        if "Lookup failed" not in hostname:
            print(f"{ip}: {hostname}")

# Example usage
# a_results and aaaa_results should be lists of IP addresses
a_results = ['93.184.216.34', '192.0.2.1']  # Example IPv4 addresses
aaaa_results = ['2606:2800:220:1:248:1893:25c8:1946', '2001:0db8:85a3:0000:0000:8a2e:0370:7334']  # Example IPv6 addresses

# Store results
store_dns_results(a_results, 'a_results.json')
store_dns_results(aaaa_results, 'aaaa_results.json')

# Load and perform reverse DNS lookup
loaded_a_results = load_dns_results('a_results.json')
loaded_aaaa_results = load_dns_results('aaaa_results.json')

reverse_result_a = reverse_dns_lookup(loaded_a_results)
reverse_result_aaaa = reverse_dns_lookup(loaded_aaaa_results)

# Print relevant answers
print_relevant_answers(reverse_result_a)
print_relevant_answers(reverse_result_aaaa)
