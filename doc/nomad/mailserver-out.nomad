#
# Docker Postfix container with ClamAV, and OpenDKIM
#
# "queue:/var/spool/postfix:rw"
# "clamav:/var/lib/clamav:rw"
# "tables:/etc/postfix/tables:ro"
# "postgrey:/etc/postgrey:ro"
#
# external DNS records should be set up as explained here:
# https://datatracker.ietf.org/doc/html/rfc6186
#
variable "key_names" {
  type    = list(string)
  default = []
}

variables {
  nomad_env              = "place-holder"
  url_prefix_env         = "place-holder"
  docker_postfix_version = "place-holder"
  clamav_mirror          = "place-holder"
  out_proxy_interfaces   = "place-holder"
  dkim_keys_prefix       = "place-holder"
  force_pull             = "place-holder"
  mynetworks             = "place-holder"
  resource_count         = 0
}

job "mailserver-out" {
  name        = "${var.nomad_env}-mailserver-out"
  region      = "global"
  datacenters = ["${var.url_prefix_env}datacenter"]
  type        = "service"

  group "mailserver-out" {
    count = var.resource_count

    update {
      max_parallel = 1
      stagger      = "120s"
    }

    vault {
      policies    = ["nomad-server"]
      change_mode = "restart"
    }

    constraint {
      attribute = meta.agent_location
      operator  = "="
      value     = "superpop"
    }

    constraint {
      attribute = meta.storage_type
      operator  = "="
      value     = "gluster"
    }

    volume "mailserver_out_queue" {
      type            = "csi"
      source          = "mailserver_out_queue"
      access_mode     = "single-node-writer"
      attachment_mode = "file-system"
      per_alloc       = true
    }

    network {
      port "smtp" { to = 25 }
      port "smtps" { to = 465 }
      port "submission" { to = 587 }
    }

    task "mailserver-out" {
      driver = "docker"

      env {
        TZ                                                    = "Europe/Amsterdam"
        POSTMASTER_EMAIL                                      = "devops@example.org"
        POSTFIX_INET_PROTOCOLS                                = "all"
        POSTFIX_MYORIGIN                                      = "${var.url_prefix_env}out-mail.example.org"
        POSTFIX_PROXY_INTERFACES                              = var.out_proxy_interfaces
        POSTFIX_MYNETWORKS                                    = "127.0.0.0/8, ${var.mynetworks}"
        POSTFIX_MYDOMAIN                                      = "example.org"
        POSTFIX_MYHOSTNAME                                    = "${var.url_prefix_env}out-mail.example.org"
        POSTFIX_MAIL_NAME                                     = "${var.url_prefix_env}out-mail.example.org"
        POSTFIX_SMTPD_RECIPIENT_RESTRICTIONS_PERMIT_MYNETWORK = "true"
        POSTFIX_SMTPD_TLS_CHAIN_FILES                         = "/secrets/postfix/mailserver.key, /local/postfix/mailserver-fullchain.pem"
        POSTFIX_SMTP_TLS_CHAIN_FILES                          = "/secrets/postfix/mailserver.key, /local/postfix/mailserver-fullchain.pem"
        POSTFIX_SMTPD_TLS_SECURITY_LEVEL                      = "may"
        POSTFIX_SMTPD_TLS_LOGLEVEL                            = 1
        POSTFIX_REJECT_INVALID_HELO_HOSTNAME                  = "false"
        POSTFIX_REJECT_NON_FQDN_HELO_HOSTNAME                 = "false"
        POSTFIX_REJECT_UNKNOWN_HELO_HOSTNAME                  = "false"
        POSTFIX_SENDER_ACCESS_REGEXP                          = "true"
        ENABLE_POSTGREY                                       = "false"
        ENABLE_CLAMAV                                         = "true"
        ENABLE_SUBMISSION_PORT                                = "true"
        ENABLE_SMTPS_PORT                                     = "true"
        ENABLE_OPENDKIM                                       = "true"
        FRESHCLAM_DB_MIRROR                                   = var.clamav_mirror
        CLAMAV_MILTER_REPORT_HOSTNAME                         = "${var.url_prefix_env}out-mail.example.org"
        OPENDKIM_SIGNINGTABLE                                 = "/local/dkim/SigningTable"
        OPENDKIM_KEYTABLE                                     = "/local/dkim/KeyTable"
        OPENDKIM_MODE                                         = "s"
        OPENDKIM_INTERNALHOSTS                                = var.mynetworks
        OPENDKIM_LOGRESULTS                                   = "true"
        OPENDKIM_LOGWHY                                       = "true"
      }

      dynamic "service" {
        for_each = ["smtp", "smtps", "submission"]

        content {
          name = "${var.nomad_env}-${service.value}-out"
          port = service.value
          tags = ["_tcp"]
          check {
            type     = "tcp"
            port     = service.value
            interval = "5s"
            timeout  = "2s"
            check_restart {
              limit           = 3
              grace           = "120s"
              ignore_warnings = true
            }
          }
        }
      }

      restart {
        attempts = 5
        delay    = "15s"
      }

      template { # trigger a restart when the docker_postfix_version changes on Consul
        destination = "local/deployment_trigger"
        data        = <<EOF
docker_postfix_version: {{ key "nomad/${var.nomad_env}/mailserver/docker_postfix_version" }}
keys_prefix: {{ key "nomad/${var.nomad_env}/mailserver/dkim_keys_prefix" }}
EOF
      }

      template {
        uid         = 999
        gid         = 100
        destination = "local/postfix/mailserver-fullchain.pem"
        data        = <<EOF
{{ key "nomad/common/mailserver/sectigo_ov_mailserver.service.ha.example.org_fullchain.pem" }}
EOF
      }

      template {
        uid         = 999
        gid         = 100
        destination = "local/postfix/sender_access.hash"
        data        = <<EOF
{{ key "nomad/common/mailserver/sender_access.hash" }}
EOF
      }

      template {
        uid         = 999
        gid         = 100
        destination = "local/postfix/client_access.cidr"
        data        = <<EOF
{{ key "nomad/common/mailserver/client_access.cidr" }}
EOF
      }

      template {
        perms       = "0600"
        uid         = 999
        gid         = 100
        destination = "secrets/postfix/mailserver.key"
        data        = <<EOF
{{ with secret "nomad/common/mailserver/sectigo_ov_mailserver.service.ha.example.org.key" }}{{ .Data.data.value }}{{ end }}
EOF
      }

      template {
        uid         = 999
        gid         = 100
        destination = "local/dkim/KeyTable"
        data        = <<EOF
{{ key "nomad/${var.nomad_env}/mailserver/KeyTable" }}
EOF
      }

      template {
        uid         = 999
        gid         = 100
        destination = "local/dkim/SigningTable"
        data        = <<EOF
{{ key "nomad/${var.nomad_env}/mailserver/SigningTable" }}
EOF
      }

      dynamic "template" {
        for_each = var.key_names
        content {
          perms       = "0600"
          uid         = 101
          gid         = 101
          destination = "secrets/dkim/${template.value}"
          data        = <<EOF
{{ with secret "nomad/${var.nomad_env}/mailserver/${template.value}" }}{{ .Data.data.value }}{{ end }}
EOF
        }
      }

      config {
        image      = "artifactory.software.example.org/geant-devops-docker/postfix:${var.docker_postfix_version}"
        force_pull = var.force_pull
        ports      = ["smtp", "smtps", "submission"]
        cap_add    = ["net_raw"]

        mount {
          type     = "bind"
          source   = "./secrets/dkim"
          target   = "/etc/dkimkeys"
          readonly = false
        }

        mount {
          type     = "bind"
          source   = "./local/postfix/sender_access.hash"
          target   = "/etc/postfix/tables/sender_access.hash"
          readonly = true
        }

        mount {
          type     = "bind"
          source   = "./local/postfix/client_access.cidr"
          target   = "/etc/postfix/tables/client_access.cidr"
          readonly = true
        }
      }

      volume_mount {
        volume      = "mailserver_out_queue"
        destination = "/var/spool/postfix"
      }

      resources {
        cpu    = 500
        memory = 3096
      }
    }
  }
}
