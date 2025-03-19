#!/bin/bash
set -e

# This script initializes a restrictive firewall in the container
# to prevent unwanted network access

# Reset iptables
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X

# Default policies - drop everything by default
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

# Allow loopback traffic
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow established connections
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow DNS lookups
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT

# Allow outbound HTTPS to api.anthropic.com only (Claude API)
iptables -A OUTPUT -p tcp --dport 443 -d api.anthropic.com -j ACCEPT

# Allow outbound HTTPS to github.com and api.github.com (for PR creation)
iptables -A OUTPUT -p tcp --dport 443 -d github.com -j ACCEPT
iptables -A OUTPUT -p tcp --dport 443 -d api.github.com -j ACCEPT

# Allow SSH outbound (for git operations)
iptables -A OUTPUT -p tcp --dport 22 -j ACCEPT

# Log dropped packets
iptables -A INPUT -j LOG --log-prefix "IPTABLES_INPUT_DROP: " --log-level 4
iptables -A OUTPUT -j LOG --log-prefix "IPTABLES_OUTPUT_DROP: " --log-level 4

# Print the new rules for verification
echo "Firewall rules configured:"
iptables -L -v