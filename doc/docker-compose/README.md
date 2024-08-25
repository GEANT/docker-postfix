# docker-compose

An example `docker-compose.yml` file:

```yaml
version: '3.8'

volumes:
  queue_out:
    driver: local
  queue_in:
    driver: local
  certs:
    driver: local
  dkim:
    driver: local
  clamav_in:
    driver: local
  clamav_out:
    driver: local
  postgrey_in:
    driver: local
  tables_in:
    driver: local
  aliases_in:
    driver: local
  asupdata_in:
    driver: local
  logs_in:
    driver: local
  logs_out:
    driver: local

services:

  mail_out:
    image: ghcr.io/mikenye/postfix:latest
    container_name: mail_out
    restart: always
    logging:
      driver: "json-file"
      options:
        max-file: "10"
        max-size: "10m"
    ports:
      - "25:25"
    environment:
      TZ: "Australia/Perth"
      POSTMASTER_EMAIL: "postmaster@yourdomain.tld"
      POSTFIX_INET_PROTOCOLS: "ipv4"
      POSTFIX_MYORIGIN: "mail.yourdomain.tld"
      POSTFIX_PROXY_INTERFACES: "your.external.IP.address"
      POSTFIX_MYNETWORKS: "your.local.LAN.subnet/prefix"
      POSTFIX_MYDOMAIN: "yourdomain.tld"
      POSTFIX_MYHOSTNAME: "mail.yourdomain.tld"
      POSTFIX_MAIL_NAME: "outbound"
      POSTFIX_SMTPD_TLS_CHAIN_FILES: "/etc/postfix/certs/privkey.pem, /etc/postfix/certs/fullchain.pem"
      POSTFIX_SMTP_TLS_CHAIN_FILES: "/etc/postfix/certs/privkey.pem, /etc/postfix/certs/fullchain.pem"
      POSTFIX_SMTPD_TLS_SECURITY_LEVEL: "may"
      POSTFIX_SMTPD_TLS_LOGLEVEL: 1
      POSTFIX_REJECT_INVALID_HELO_HOSTNAME: "false"
      POSTFIX_REJECT_NON_FQDN_HELO_HOSTNAME: "false"
      POSTFIX_REJECT_UNKNOWN_HELO_HOSTNAME: "false"
      ENABLE_OPENDKIM: "true"
      OPENDKIM_SIGNINGTABLE: "/etc/mail/dkim/SigningTable"
      OPENDKIM_KEYTABLE: "/etc/mail/dkim/KeyTable"
      OPENDKIM_MODE: "s"
      OPENDKIM_INTERNALHOSTS: "your.local.LAN.subnet/prefix"
      OPENDKIM_LOGRESULTS: "true"
      OPENDKIM_LOGWHY: "true"
      ENABLE_CLAMAV: "true"
      CLAMAV_MILTER_REPORT_HOSTNAME: "mail.yourdomain.tld"
    volumes:
      - "certs:/etc/postfix/certs:ro"
      - "dkim:/etc/mail/dkim:rw"
      - "clamav_out:/var/lib/clamav:rw"
      - "queue_out:/var/spool/postfix:rw"
      - "logs_out:/var/log:rw"

  mail_in:
    image: ghcr.io/mikenye/postfix:latest
    container_name: mail_in
    restart: always
    logging:
      driver: "json-file"
      options:
        max-file: "10"
        max-size: "10m"
    dns:
      - 8.8.8.8
      - 8.8.4.4
    ports:
      - "2525:25"
    environment:
      TZ: "Australia/Perth"
      POSTMASTER_EMAIL: "postmaster@yourdomain.tld"
      POSTFIX_INET_PROTOCOLS: "ipv4"
      POSTFIX_MYORIGIN: "mail.yourdomain.tld"
      POSTFIX_PROXY_INTERFACES: "your.external.IP.address"
      POSTFIX_MYDOMAIN: "yourdomain.tld"
      POSTFIX_MYHOSTNAME: "mail.yourdomain.tld"
      POSTFIX_MAIL_NAME: "inbound"
      POSTFIX_SMTPD_TLS_CHAIN_FILES: "/etc/postfix/certs/privkey.pem, /etc/postfix/certs/fullchain.pem"
      POSTFIX_SMTP_TLS_CHAIN_FILES: "/etc/postfix/certs/privkey.pem, /etc/postfix/certs/fullchain.pem"
      POSTFIX_SMTPD_TLS_SECURITY_LEVEL: "may"
      POSTFIX_SMTPD_TLS_LOGLEVEL: 1
      POSTFIX_RELAYHOST: "exchange.server.IP.addr"
      POSTFIX_RELAY_DOMAINS: "yourdomain.tld,someotherdomain.tld"
      POSTFIX_DNSBL_SITES: "hostkarma.junkemailfilter.com=127.0.0.2, bl.spamcop.net, cbl.abuseat.org=127.0.0.2, zen.spamhaus.org"
      ENABLE_SUBMISSION_PORT: "true"
      ENABLE_OPENDKIM: "true"
      OPENDKIM_MODE: "v"
      OPENDKIM_LOGRESULTS: "true"
      OPENDKIM_LOGWHY: "true"
      ENABLE_SPF: "true"
      ENABLE_CLAMAV: "true"
      CLAMAV_MILTER_REPORT_HOSTNAME: "mail.yourdomain.tld"
      ENABLE_POSTGREY: "true"
      ENABLE_LDAP_RECIPIENT_ACCESS: "true"
      POSTFIX_LDAP_SERVERS: "active.directory.server.IP,active.directory.server.IP"
      POSTFIX_LDAP_BIND_DN: "CN=mailrelay,OU=Service Accounts,OU=Users,DC=yourdomain,DC=tld"
      POSTFIX_LDAP_BIND_PW: "12345"
      POSTFIX_LDAP_SEARCH_BASE: "DC=yourdomain,DC=tld"
    volumes:
      - "certs:/etc/postfix/certs:ro"
      - "queue_in:/var/spool/postfix:rw"
      - "clamav_in:/var/lib/clamav:rw"
      - "postgrey_in:/etc/postgrey:ro"
      - "tables_in:/etc/postfix/tables:ro"
      - "aliases_in:/etc/postfix/local_aliases:ro"
      - "logs_in:/var/log:rw"
```

It is recommended to make your volume mounts somewhere you can access them, so you can edit files, load certificates, view logs easily, etc.

For example, you could map through to a known local path:

```yaml
volumes:
  queue_out:
    driver: local
      type: 'none'
      o: 'bind'
      device: '/opt/mail/queue_out'
...
```

...or, another example useing NFS to a filer/server, eg:

```yaml
volumes:
  queue_out:
    driver: local
      type: nfs
      o: addr=1.2.3.4,rw
      device: ":/vol/mail/queue_out"
...
```
