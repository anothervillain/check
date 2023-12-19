## **About this tool/script**
Usage: ```check domain.tld``` to lookup relevant DNS, WHOIS and SSL information in your terminal.

<kbd>
  <img src="https://github.com/zhk3r/check/assets/37957791/45595ed8-8460-4e7a-9a24-b6a66f0e067e">
</kbd>

## **Installation and setup**
| Copy-paste this!                                     | "But to where?" you ask!                      |
| :----------------------------------------------------|:----------------------------------------------|
| ```export PATH="check:$PATH"```                      | Add to your .zshrc or equivalent.             |
| ```source ~/check/check_function.zsh```              | Add to your .zshrc or equivalent.             |
| ```git clone https://github.com/zhk3r/check.git```   | to clone this repo.                           |
| ```chmod +x ~/check/update_check.sh```               | to make the update script run.                |
| ```exec zsh```                                       | Restart your terminal or shell                |

You should be good to check out some domains now! :)

#### Updating the script
After updating the script ```update_check.sh``` you will have restart your terminal ```exec zsh``` (or equivalent)

# **Lookup a domains information**

```check domain.tld``` will first:

1) Look for 'status: NXDOMAIN' in the header information from the initial dig a return.
2) Check if the Start of Authority (SOA) is *charm.norid.no* to determine if the domain is in QUARANTINE.

**If the domain doesn't pass these checks the script will inform of such and stop running.**

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

There are a bunch of hidden checks that happen during the script - sometimes it might get stuck on a record lookup, that's because that record is being stored and used for another check later on etc. There's a bunch of stuff like that in the script - in cases where it 'loads' just leave it and it'll continue when it's done processing whatever logic it needs to.

### **Dependencies**

In order for the script to run you will need the following:

| Name    | Command                        | Why
| :-------| :------------------------------| :----------------------------------------|
| python3 | ```sudo apt install python3``` | Used for reverse dns lookup logic        |
| dig     | ```sudo apt install dig```     | Used for most dns commands               |
| whois   | ```sudo apt install whois```   | Used to lookup registrar information     |
| openssl | ```sudo apt install openssl``` | Used to test SSL connectivity            |
| curl    | ```sudo apt install curl```    | Used to test SSL connectivity            |
| lolcat  | ```sudo apt install lolcat```  | Used to color some output                |

> You probably have most of these already, you could remove lolcat from line 76 if you so desire.
