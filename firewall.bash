#!/bin/bash

# Disabling ufw
ufw --force disable

# Resetting ufw
ufw --force reset

# Deny All Incoming Connections
ufw default deny incoming

# Allow All Outgoing Connections
ufw default allow outgoing

# Allow SSH connection/Limit
ufw limit 5050/tcp

# HTTP
ufw allow 80/tcp

# HTTPS
ufw allow 443/tcp

# Enabling ufw
ufw --force enable
