#!/usr/bin/with-contenv bash
# shellcheck shell=bash

DOVECOT_CONF="/etc/dovecot/dovecot.conf"
DOVECOT_DEBUG_CONF="/etc/dovecot/debug.conf"

if [ "${POSTFIX_SASL_AUTH}" = "true" ]; then
    truncate -s 0 $DOVECOT_CONF
    {
        echo "!include_try /usr/share/dovecot/protocols.d/*.protocol"
        echo "!include_try debug.conf"
        echo ""
        echo "# Auth configuration"
        echo "disable_plaintext_auth = no"
        echo "auth_mechanisms = plain login"
        echo "passdb {"
        echo "  driver = passwd-file"
        echo "  args = scheme=SHA512-CRYPT /secrets/passwd"
        echo "}"
        echo "userdb {"
        echo "  driver = static"
        echo "  args = uid=nobody gid=nogroup home=/nonexistent"
        echo "}"
        echo ""
        echo "# Service configuration"
        echo "service auth-worker {"
        echo "}"
        echo "service auth {"
        echo "  unix_listener /var/spool/postfix/private/auth {"
        echo "    mode = 0660"
        echo "    user = postfix"
        echo "    group = postdrop"
        echo "  }"
        echo "}"
    } >"${DOVECOT_CONF}"
fi

if [ "${POSTFIX_SASL_AUTH_DEBUG}" = "true" ]; then
    {
        echo "# debug"
        echo "auth_verbose = yes"
        echo "auth_verbose_passwords = no"
        echo "auth_debug = yes"
        echo "auth_debug_passwords = yes"
        echo "mail_debug = yes"
        echo "verbose_ssl = yes"
    } >"${DOVECOT_DEBUG_CONF}"
fi
