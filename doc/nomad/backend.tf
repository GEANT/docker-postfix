terraform {
  required_providers {
    nomad = {
      source  = "hashicorp/nomad"
      version = "~> 2.3"
    }
    consul = {
      source  = "hashicorp/consul"
      version = "~> 2.20"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.2"
    }
  }

  backend "consul" {
    path = "nomad/terraform_states/mailserver/tfstate"
    lock = "true"
  }
  required_version = ">= 1.4"
}

provider "consul" {
  address    = "consul.service.ha.example.org:443"
  scheme     = "https"
  ca_file    = "/etc/ssl/certs/COMODO_OV.crt"
  datacenter = "datacenter"
}

provider "vault" {
  address          = "https://master.vault.service.ha.example.org:8200"
  ca_cert_file     = "/etc/ssl/certs/COMODO_OV.crt"
  skip_child_token = true
}

data "consul_keys" "nomad" {
  datacenter = "datacenter"
  key {
    name = "nomad_address"
    path = "nomad/${terraform.workspace}/nomad/addr"
  }
  key {
    name = "token_path"
    path = "nomad/${terraform.workspace}/nomad/token_path"
  }
}

data "vault_kv_secret_v2" "nomad_token" {
  mount = "nomad"
  name  = data.consul_keys.nomad.var.token_path
}

provider "nomad" {
  secret_id = data.vault_kv_secret_v2.nomad_token.data.value
  address   = data.consul_keys.nomad.var.nomad_address
  ca_file   = "/etc/ssl/certs/COMODO_OV.crt"
}
