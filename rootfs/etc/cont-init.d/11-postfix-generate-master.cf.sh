#!/usr/bin/with-contenv bash
# shellcheck shell=bash

POSTFIX_MASTERCF_FILE="/etc/postfix/master.cf"
POSTFIX_MASTERCF_ORIGINAL_FILE="/etc/postfix/master.cf.original"

# Refresh the master.cf. This prevents duplicate entries on container restart
cp -v ${POSTFIX_MASTERCF_ORIGINAL_FILE} ${POSTFIX_MASTERCF_FILE}

# Enable postscreen
# See: http://www.postfix.org/POSTSCREEN_README.html
# Comment out the "smtp inet ... smtpd" service in master.cf
sed -i 's/^smtp *inet.*smtpd$/#&/' $POSTFIX_MASTERCF_FILE
# Uncomment the new "smtpd pass ... smtpd" service in master.cf
sed -i '/^#smtpd *pass.*smtpd$/s/^#//g' $POSTFIX_MASTERCF_FILE
# Uncomment the new "smtp inet ... postscreen" service in master.cf
sed -i '/^#smtp *inet.*postscreen$/s/^#//g' $POSTFIX_MASTERCF_FILE
# Uncomment the new "tlsproxy unix ... tlsproxy" service in master.cf
sed -i '/^#tlsproxy *unix.*tlsproxy$/s/^#//g' $POSTFIX_MASTERCF_FILE
# Uncomment the new "dnsblog unix ... dnsblog" service in master.cf
sed -i '/^#dnsblog *unix.*dnsblog$/s/^#//g' $POSTFIX_MASTERCF_FILE

# Do we enable & configure spf-engine?
if [ "${ENABLE_SPF}" = "true" ]; then
    echo "policy  unix  -       n       n       -       0       spawn" >>"${POSTFIX_MASTERCF_FILE}"
    echo "    user=nobody argv=/usr/local/lib/policyd-spf-perl" >>"${POSTFIX_MASTERCF_FILE}"
fi

# Please note that on Debian submission port (587) and smtps port (465) are called
# "submission" and "submissions" either in /etc/postfix/master.cf and in /etc/services
# Do we enable & configure submission port?
if [ "${ENABLE_SUBMISSION_PORT}" = "true" ]; then
    sed -i '/^#submission *inet.*smtpd$/s/^#//g' $POSTFIX_MASTERCF_FILE
fi
# Do we enable & configure smtps port?
if [ "${ENABLE_SMTPS_PORT}" = "true" ]; then
    sed -i '/^#submissions *inet.*smtpd$/s/^#//g' $POSTFIX_MASTERCF_FILE
fi

# https://www.postfix.org/postconf.5.html#postscreen_upstream_proxy_protocol
if [ -n "${ENABLE_HAPROXY_PROTOCOL}" ]; then
    cat <<'EOF' >${POSTFIX_MASTERCF_FILE}
# Enable haproxy protocol
smtp      inet  n       -       n       -       1       smtpd
    -o smtpd_upstream_proxy_protocol=haproxy
smtpd     pass  -       -       n       -       -       smtpd
submission inet n       -       n       -       -       smtpd
    -o syslog_name=postfix/submission
    -o smtpd_tls_security_level=encrypt
    -o smtpd_sasl_auth_enable=yes
    -o smtpd_upstream_proxy_protocol=haproxy
submissions     inet  n       -       y       -       -       smtpd
    -o syslog_name=postfix/smtps
    -o smtpd_tls_wrappermode=yes
    -o smtpd_sasl_auth_enable=yes
    -o smtpd_upstream_proxy_protocol=haproxy
pickup    unix  n       -       n       60      1       pickup
cleanup   unix  n       -       n       -       0       cleanup
qmgr      unix  n       -       n       300     1       qmgr
tlsmgr    unix  -       -       n       1000?   1       tlsmgr
rewrite   unix  -       -       n       -       -       trivial-rewrite
bounce    unix  -       -       n       -       0       bounce
defer     unix  -       -       n       -       0       bounce
trace     unix  -       -       n       -       0       bounce
verify    unix  -       -       n       -       1       verify
flush     unix  n       -       n       1000?   0       flush
proxymap  unix  -       -       n       -       -       proxymap
proxywrite unix -       -       n       -       1       proxymap
smtp      unix  -       -       n       -       -       smtp
relay     unix  -       -       n       -       -       smtp
    -o syslog_name=${multi_instance_name?{$multi_instance_name}:{postfix}}/$service_name
showq     unix  n       -       n       -       -       showq
error     unix  -       -       n       -       -       error
retry     unix  -       -       n       -       -       error
discard   unix  -       -       n       -       -       discard
local     unix  -       n       n       -       -       local
virtual   unix  -       n       n       -       -       virtual
lmtp      unix  -       -       n       -       -       lmtp
anvil     unix  -       -       n       -       1       anvil
scache    unix  -       -       n       -       1       scache
postlog   unix-dgram n  -       n       -       1       postlogd
EOF
else
    # Enable postscreen
    # See: http://www.postfix.org/POSTSCREEN_README.html
    # Comment out the "smtp inet ... smtpd" service in master.cf
    sed -i 's/^smtp *inet.*smtpd$/#&/' $POSTFIX_MASTERCF_FILE
    # Uncomment the new "smtpd pass ... smtpd" service in master.cf
    sed -i '/^#smtpd *pass.*smtpd$/s/^#//g' $POSTFIX_MASTERCF_FILE
    # Uncomment the new "smtp inet ... postscreen" service in master.cf
    sed -i '/^#smtp *inet.*postscreen$/s/^#//g' $POSTFIX_MASTERCF_FILE
    # Uncomment the new "tlsproxy unix ... tlsproxy" service in master.cf
    sed -i '/^#tlsproxy *unix.*tlsproxy$/s/^#//g' $POSTFIX_MASTERCF_FILE
    # Uncomment the new "dnsblog unix ... dnsblog" service in master.cf
    sed -i '/^#dnsblog *unix.*dnsblog$/s/^#//g' $POSTFIX_MASTERCF_FILE
    # Enable haproxy protocol support in postscreen
    sed -i '/^#postscreen *inet.*postscreen$/s/^#//g' $POSTFIX_MASTERCF_FILE
    # on Debian submission port (587) and smtps port (465) are called
    # "submission" and "submissions" either in /etc/postfix/master.cf and in /etc/services
    # Do we enable & configure submission port?
    if [ "${ENABLE_SUBMISSION_PORT}" = "true" ]; then
        sed -i '/^#submission *inet.*smtpd$/s/^#//g' $POSTFIX_MASTERCF_FILE
    fi
    # Do we enable & configure smtps port?
    if [ "${ENABLE_SMTPS_PORT}" = "true" ]; then
        sed -i '/^#smtps *inet.*smtpd$/s/^#//g' $POSTFIX_MASTERCF_FILE
    fi
fi
