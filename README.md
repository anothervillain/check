# **check.sh**
Usage: ```check domain.tld``` to quickly check domain info in your terminal.

<kbd>
<img src="https://github.com/zhk3r/check/assets/37957791/a39f5de2-2584-4843-8f4f-28c0b8fe74b3">
</kbd>

## **Installation and setup**

> Copy and paste into your terminal:
<pre lang="bash">
bash -c "$(curl -fsSL https://raw.githubusercontent.com/zhk3r/check/testing/install.sh)"
</pre>

> Add to your bash_aliases, .zshrc or whatever shell you might use:
<pre lang="bash">
alias check='~/check/check.sh'
</pre>


##### Windows Subsystem for Linux setup help and instructions here:

https://github.com/zhk3r/wsl

## **Lookup relevant domain information**

```check domain.tld``` will first:

<details>
  <summary>Check if the domain EXISTS</summary>
if 'status NXDOMAIN' is found, that indicates that the domain does not exist, the script will stop running here.
</details>
<details>
  <summary>Check if the domain is in QUARANTINE</summary>
if the domain has 'status: NXDOMAIN' and SOA starts at 'charm.norid.no' the script will whois the domain and look for "No match", if that string isn't found the script will report the domain as in QUARANTINE.
</details>
<details>
  <summary>Performs WHOIS to identify Registrar</summary>
will show the name of either the Registry (White Label) or Registrar. For .no domains there's logic that converts REG-HANDLE into REG-NAMES appended in [brackets] behind REG-HANDLE.
</details>
<details>
  <summary>Determine DNS management</summary>
based on the nameservers found for the domain (from a pre-defined pattern array) the script will tell you where the domain is managed.
</details>

**This information is cached for 15 seconds so you can -flag for further information.** Repeating a check on the same domain after the cache is emptied repeats the preliminary checks on the domain.

```check domain.tld -mail```

1) MX records.
2) SPF records (with coloring of known hosts vs mass-senders).
3) DMARC and DKIM records.
4) Email provider guesser (with lots of pre-defined logic)

```check domain.tld -host```

1) A + AAAA records.
2) Forwarding of all types HTTP-status and TXT redirects.
3) Nameservers (and their corresponding IPv4 adresses).
4) Reverse DNS lookup of all found A + AAAA records.
5) Modified SSL output displaying CN, start & expiry and issuer.
6) Hosting provider guesser (with lots of pre-defined logic)

*If the information found is not pre-defined in an array, the script will guess the host based on the first IPv4 address by whois (IP) and extracting 4 levels of 'OrgName' and 'NetName'*

```check domain.tld -cert```

Connects to the domain using curl (both secure & insecure flags) to display TLS/SSL information. There's a fair amount of output sanitation, so if the connection fails it automatically retries without any modified output. If the connection fails without any modifications, a message will be printed saying there's no SSL certificate available.

```check domain.tld -ssl```

Connects to the domain using openssl protocol to display the full certificate chain. The script will finish the handshake immediately after making the connection. Some of the output is colored, but it's mostly just for troubleshooting SSL issues.

```check domain.tld -rdns```

This is a different Python script from the one used within check_host.sh (-host flag) -- It uses tabulate and colorama for aesthetics. This flag is useful when trying to troubleshoot PTR and SOA connectivity issues in terms of hosting.

```check domain.tld -whois```

**THIS IS TEMPORARY AND IN EARLY TESTING** The script heavily modifies the output from registrarwhois.norid to serve only useful information.

```check domain.tld -all```

1) Performs preliminary tests to see if the domain is valid
2) Pulls the information from check_mail.sh (-mail flag)
3) Pulls the information from check_host.sh (-host flag)

**This is very close to the main branch version of ```check```**

```check -help```

Shows the help section! :smile:

#### Flags

<details>
  <summary><b>All -flags support single or double dash, and have aliases.</b></summary>
  <br>
  <code>+all, -all, -a</code>
  <br>
  <code>-mail, -email, -m, -e</code>
  <br>
  <code>-host, -h</code>
  <br>
  <code>-ssl, -s</code>
  <br>
  <code>-cert, -c</code>
  <br>
  <code>-whois, -w</code>
  
</details>

### **Output and sanitazion of information**

There are quite a few 'hidden' checks that happen during the script, it stores certain information in temporary files for use later. The logic is far from perfect, but for the most part in my own testing the output is sanitized OK. A lot of it in regards to reverse-dns lookups and registrar name conversions.

There are a lot of pre-defined patterns and arrays defined on top of a lot of 'hidden' checks that happen. The script will store information in temporary files for later use (especially in terms of reverse-dns-lookups), the logic is far from perfect but in most of my testing these functions 

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


#### Contribution
My coworkers for input on the logic, filtering and output of the script <3

#### License
This project is licensed under Apache 2.0.

#### Contact
For questions or contributions, contact me wherever you can find me :)
