#!/usr/bin/with-contenv bash
# shellcheck shell=bash

# Make log dirs
# Create log dir for piaware
install -o nobody -g nogroup -m 0755 -d \
    /var/log/opendkim \
    /var/log/postfix \
    /var/log/postgrey \
    /var/log/postgrey_whitelist_update \
    /var/log/syslogd \
    /var/log/dovecot

# Postfix
mkdir -p /var/spool/postfix
chown root:root /var/spool/postfix
mkdir -p /var/spool/postfix/active
chown -R postfix /var/spool/postfix/active
mkdir -p /var/spool/postfix/bounce
chown -R postfix /var/spool/postfix/bounce
mkdir -p /var/spool/postfix/corrupt
chown -R postfix /var/spool/postfix/corrupt
mkdir -p /var/spool/postfix/defer
chown -R postfix /var/spool/postfix/defer
mkdir -p /var/spool/postfix/deferred
chown -R postfix /var/spool/postfix/deferred
mkdir -p /var/spool/postfix/flush
chown -R postfix /var/spool/postfix/flush
mkdir -p /var/spool/postfix/hold
chown -R postfix /var/spool/postfix/hold
mkdir -p /var/spool/postfix/incoming
chown -R postfix /var/spool/postfix/incoming
mkdir -p /var/spool/postfix/maildrop
chown -R postfix:postdrop /var/spool/postfix/maildrop
mkdir -p /var/spool/postfix/pid
chown -R root:root /var/spool/postfix/pid
mkdir -p /var/spool/postfix/private
chown -R postfix /var/spool/postfix/private
mkdir -p /var/spool/postfix/public
chown -R postfix:postdrop /var/spool/postfix/public
mkdir -p /var/spool/postfix/saved
chown -R postfix /var/spool/postfix/saved
mkdir -p /var/spool/postfix/trace
chown -R postfix /var/spool/postfix/trace
# chown -R root /etc/postfix/tables            # read-only by Nomad, permissions set by Nomad
# chmod -R g-w,o-w /etc/postfix/tables         # read-only by Nomad, permissions set by Nomad
# chown -R root /etc/postfix/local_aliases     # read-only by Nomad, permissions set by Nomad
# chmod -R g-w,o-w /etc/postfix/local_aliases  # read-only by Nomad, permissions set by Nomad

# OpenDKIM
mkdir -p /etc/mail/dkim
chown -R opendkim /etc/mail/dkim

# Postgrey
mkdir -p /var/spool/postfix/postgrey
chown -R postgrey /var/spool/postfix/postgrey

