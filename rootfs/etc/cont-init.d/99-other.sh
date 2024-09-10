#!/usr/bin/with-contenv bash
# shellcheck shell=bash

# Add precedence to IPv4
if [ -n "${PREFER_IPV4}" ]; then
  echo 'precedence ::ffff:0:0/96 100' >>/etc/gai.conf
fi
