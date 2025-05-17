# DNS Performance Test for macOS

Shell script to test the performance of the most popular DNS resolvers. Modification of [dnsperftest](https://github.com/cleanbrowsing/dnsperftest) with QoL improvements for macOS.

![enter image description here](https://raw.githubusercontent.com/joshuathomas3/dnsperftest/refs/heads/master/demo.png)

## Features

- Tests DNS lookups against 10 most-visited websites in the United Kingdom according to [SimilarWeb](https://www.similarweb.com/top-websites/united-kingdom/) by default.
- DNS resolvers and domain names stored in external text files for editing
- Flushes macOS DNS cache before test for more accurate results
- Creates .csv file for sharing and analysis

DNS resolvers included by default:

- [Cloudflare 1.1.1.1](https://one.one.one.one/dns/)
- [Google 8.8.8.8](https://developers.google.com/speed/public-dns)
- [Quad9 9.9.9.9](https://www.quad9.net/service/service-addresses-and-features/)
- [OpenDNS](https://www.opendns.com/setupguide/)
- [CleanBrowsing Security Filter](https://cleanbrowsing.org/)
- [Adguard DNS Default Servers](https://adguard-dns.io/en/public-dns.html)
- [Control D Unfiltered DNS](https://controld.com/free-dns)

# Requirements

## Prerequisites

Libraries:

- [bc](https://www.gnu.org/software/bc/)
- [dig](https://www.isc.org/bind/)

Operating System: Tested on macOS Sequoia 15.5

## Install via Homebrew

Step 1: Install Homebrew if you have not already at [brew.sh](brew.sh)
Step 2: Install bc and dig

```
 brew install bc bind
 git clone https://github.com/joshuathomas3/dnsperftest-for-macos
```

IPv4 Mode:

```
bash ./dnstest.sh
```

IPv6 Mode:

```
bash ./dnstest.sh ipv6
```
