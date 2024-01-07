# **check.sh**
Usage: ```check domain.tld``` to quickly lookup domain info like DNS, WHOIS and SSL data in your terminal.

<kbd>
<img src="https://github.com/zhk3r/check/assets/37957791/e47e87ab-1ed1-49c6-8299-cfe066ed7c3a">
</kbd>


## **Installation and setup**
> Fastest way to install, copy and run the following command:

<pre lang="bash">
sh -c "$(curl -fsSL https://raw.githubusercontent.com/zhk3r/check/testing/install.sh)
  
</pre>
> If you like doing stuff manually you have to:

| Copy-paste this                                      | Where                                                 |
| :----------------------------------------------------|:------------------------------------------------------|
| ```export PATH="check:$PATH"```                      | Add to your .zshrc or equivalent.                     |
| ```exprt PATH=\"\$PATH:$pip3_path\"```               | Add to your .zshrc or equvialent.                     |
| ```source ~/check/check_function.zsh```              | Add to your .zshrc or equivalent.                     |
| ```git clone https://github.com/zhk3r/check.git```   | Into your terminal                                    |
| ```chmod +x rdns.py hostguess.py update_check.sh```  | Into your terminal, makes the scripts run.            |
| ```exec zsh```                                       | Restart your terminal/shell                           |

## **Lookup relevant domain information**

```check domain.tld``` will first:

<details>
  <summary>Check for 'status: NXDOMAIN' in the header information</summary>
this status indicates that the domain does not exist, the script will stop here.
</details>
<details>
  <summary>Check if the domain is in QUARANTINE</summary>
if the domain has 'status: NXDOMAIN' and SOA starts at 'charm.norid.no' the script will whois the domain and look for "No match" - if that string isn't found the script will report the domain as in QUARANTINE.
</details>

- [x] **Passing both checks lets the script look for:**

| What    | Content   |  Explanation                                      |
| :-------|:----------|:--------------------------------------------------|
| RECORD  | A         | A records - IPv4 addresses.                       |
| RECORD  | AAAA      | AAAA records - IPv6 addresses.                    |
| FORWARD | HTTP      | HTTP-STATUS (301, 302, 307...) forwarding         |
| FORWARD | REDIR     | DNS redir TXT based fowarding                     |
| FORWARD | PARKED    | TXT containing ```parked```                       |
| RECORD  | MX        | MX records                                        |
| RECORD  | SPF       | ```v=spf``` in TXT and SPF type records.          |
| RECORD  | NS        | Nameservers                                       |
| RECORD  | PTR       | Reverse DNS lookup of the A & AAAA records        |
| GUESS   | LOGIC     | Attempts to guess the host :)                     |
| WHOIS   | REGISTRAR | WHOIS to pull the registrar name                  |
| CURL    | SSL CERT  | With and without insecure flag to check SSL       |

## Secondary functions

These are supporting functions to the main script (no flag support)
<pre lang="bash">checkcert</pre>

Add-on function that retrieves and displays TLS certificate details for the specified domain using curl. If the initial attempt fails, it retries without alterations to the output formatting and color-codes (asks the user to retry [Y/n])

<pre lang="bash">checkssl</pre>

Add-on function that uses the openssl s_client command to connect to the specified domain over SSL/TLS on port 443 and displays the entire SSL/TLS certificate chain. Can be useful when you need that information for troubleshooting.

<pre lang="bash">rdns</pre>

Add-on function to reverse dns lookup the given domains A and AAAA record. The output lets you know the reporting server (PTR) or whether the result is Start of Authority (SOA).

<kbd>
  <img src="https://github.com/zhk3r/check/assets/37957791/0e34aeaa-84d7-4a8b-a7c8-2158f6d03bdd)">
</kbd>

### **Output and sanitazion of information**

There are quite a few 'hidden' checks that happen during the script, it stores certain information in temporary files for use later. The logic is far from perfect, but for the most part in my own testing the output is sanitized OK. A lot of it in regards to reverse-dns lookups and registrar name conversions.

### **Dependencies**

> In order for the script to run you will need the following:

| Name    | Command                        | Why
| :-------| :------------------------------| :----------------------------------------|
| python3 | ```sudo apt install python3``` | Used for reverse dns lookup logic        |
| pip3    | ```suo install python-pip3```  | Used for (add-on) rdns lookup logic      |
| pip3    | ```pip3 install tabulate```    | Used to put rdns info into a table       |
| pip3    | ```pip3 install colorama```    | Used to color rdns lookups.              |
| dig     | ```sudo apt install dig```     | Used for most dns commands               |
| whois   | ```sudo apt install whois```   | Used to lookup registrar information     |
| openssl | ```sudo apt install openssl``` | Used to test SSL connectivity            |
| curl    | ```sudo apt install curl```    | Used to test SSL connectivity            |
| lolcat  | ```sudo apt install lolcat```  | Used to color some output                |

> You probably have most of these already, you could remove lolcat from line 120 if you so desire.

#### Contribution
My coworkers for input on the logic, filtering and output of the script <3

#### License
This project is licensed under Apache 2.0.

#### Contact
For questions or contributions, contact me wherever you can find me :)
