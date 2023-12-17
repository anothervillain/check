## **About this tool/script**
Usage: ```check domain.tld``` to lookup relevant DNS, WHOIS and SSL information in your terminal.

![front](https://github.com/zhk3r/check/assets/37957791/2103887d-3946-44cc-bd0b-edc2205a0b27)


## **Installation and setup**
| Copy-paste this!                                     | "But to where you ask"                        |
| :----------------------------------------------------|:----------------------------------------------|
| ```export PATH="check:$PATH"```                      | Add to your .zshrc or equivalent.             |
| ```source ~/check/check_function.zsh```              | Add to your .zshrc or equivalent.             |
| ```git clone https://github.com/zhk3r/check.git```   | to clone this repo.                           |
| ```chmod +x ~/check/update_check.sh```               | to make the update script run.                |
| ```source .zshrc```                                  | or equivalent (restart terminal)              |

You should be good to go!

### Updating the script
After updating the script you will have to either, 

1) ```source .zshrc``` (or equivalent).
2) Restart your terminal.
3) Open up a new terminal tab.

# **Lookup a domains information**

```check domain.tld``` will first:
```
Look for 'status: NXDOMAIN' in the header information from the initial dig a return.
Check if the Start of Authority (SOA) is *charm.norid.no* to determine if the domain is in QUARANTINE.
```
*If the domain doesn't pass these checks the script will inform of such and stop running.*

If the domain passes the first tests the script will continue to check for the following:

| ~       | ~         | ~                                                 |
| :-------|:----------|:--------------------------------------------------|
| RECORD  | A         | Looks up all A records.                           |
| RECORD  | AAAA      | Looks up all AAAA records.                        |
| FORWARD | HTTP      | HTTP-STATUS (301, 307, etc) forwarding            |
| FORWARD | REDIR     | TXT ```_redir``` forwarding                       |
| FORWARD | PARKED    | TXT containing ```parked```                       |
| RECORD  | MX        | MX records                                        |
| RECORD  | SPF       | Looks for SPF in ```TXT``` and ```SPF``` records  |
| RECORD  | NS        | Nameservers                                       |
| REVERSE | DNS       | Performs a reverse-dns lookup on both A & AAAA    |
| WHOIS   | REGISTRAR | WHOIS to pull the registrar name                  |
| CURL    | SSL CERT  | Curls with and without insecure flag to check SSL |

  ### Secondary functions

  | Command         | What it does
  | :---------------| :------------------------------------------------------------------------------------------------------|
  | ```checkcert``` | can be used to display a bit more information about the SSL certificate.                               |
  | ```checkssl```  | can be used to connect to the hostname using ```openssl``` protocol, displaying the certificate chain. |

## **Output and sanitazion of information**

There are some hidden checks that happen during some of the checks, these include but are possibly not limited to:

Some of the functions sanitize the output in order to show only relevant information. Some of these checks includes the WHOIS lookup which accounts for a subdomain being input, WHOIS lookup where a secondary lookup is done if special paramaters are met. The reverse DNS lookup part also has rules that sanitizes the information if the result isn't relevant (in.addr.rpa, SOA).

### **Dependencies**

- dig
- whois
- openssl
- curl
- lolcat *(not strictly necessary, you can remove* ```| lolcat``` *from line 76)*
