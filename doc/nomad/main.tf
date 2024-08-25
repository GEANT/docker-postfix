# Check README.md
#
data "consul_keys" "mailserver" {
  datacenter = "datacenter"
  key {
    name = "nomad_env"
    path = "nomad/${terraform.workspace}/common/nomad_env"
  }
  key {
    name = "url_prefix_env"
    path = "nomad/${terraform.workspace}/common/url_prefix_env"
  }
  key {
    name = "gluster_env"
    path = "nomad/${terraform.workspace}/common/gluster_env"
  }
  key {
    name = "disk_min_size"
    path = "nomad/${terraform.workspace}/mailserver/disk_min_size"
  }
  key {
    name = "disk_max_size"
    path = "nomad/${terraform.workspace}/mailserver/disk_max_size"
  }
  key {
    name = "docker_postfix_version"
    path = "nomad/${terraform.workspace}/mailserver/docker_postfix_version"
  }
  key {
    name = "clamav_mirror"
    path = "nomad/${terraform.workspace}/mailserver/clamav_mirror"
  }
  key {
    name = "proxy_interfaces"
    path = "nomad/${terraform.workspace}/mailserver/proxy_interfaces"
  }
  key {
    name = "out_proxy_interfaces"
    path = "nomad/${terraform.workspace}/mailserver/out_proxy_interfaces"
  }
  key {
    name = "key_names"
    path = "nomad/${terraform.workspace}/mailserver/key_names"
  }
  key {
    name = "resource_count"
    path = "nomad/${terraform.workspace}/mailserver/resource_count"
  }
  key {
    name = "dkim_keys_prefix"
    path = "nomad/${terraform.workspace}/mailserver/dkim_keys_prefix"
  }
  key {
    name = "force_pull"
    path = "nomad/${terraform.workspace}/mailserver/force_pull"
  }
  key {
    name = "mynetworks"
    path = "nomad/common/mailserver/mynetworks"
  }
  key {
    name = "relay_domains"
    path = "nomad/${terraform.workspace}/mailserver/relay_domains"
  }
  key {
    name = "transport"
    path = "nomad/${terraform.workspace}/mailserver/transport"
  }
}

locals {
  gluster_env   = data.consul_keys.mailserver.var.gluster_env
  disk_min_size = data.consul_keys.mailserver.var.disk_min_size
  disk_max_size = data.consul_keys.mailserver.var.disk_max_size
}

data "nomad_plugin" "kadalu" {
  plugin_id        = "kadalu-csi"
  wait_for_healthy = true
}

# Mail server IN volumes
#
resource "nomad_csi_volume" "mailserver_in_queue" {
  depends_on = [data.nomad_plugin.kadalu]
  lifecycle {
    prevent_destroy = true
  }

  count        = data.consul_keys.mailserver.var.resource_count
  plugin_id    = "kadalu-csi"
  volume_id    = "mailserver_in_queue[${count.index}]"
  name         = "mailserver_in_queue[${count.index}]"
  capacity_min = local.disk_min_size
  capacity_max = local.disk_max_size

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }

  parameters = {
    kadalu_format   = "native"
    storage_name    = "csi-pool"
    gluster_hosts   = "${local.gluster_env}-gluster01.example.org,${local.gluster_env}-gluster02.example.org,${local.gluster_env}-gluster03.example.org"
    gluster_volname = "csi"
  }
}

# Mail server OUT volumes
#
resource "nomad_csi_volume" "mailserver_out_queue" {
  depends_on = [data.nomad_plugin.kadalu]
  lifecycle {
    prevent_destroy = true
  }

  count        = data.consul_keys.mailserver.var.resource_count
  plugin_id    = "kadalu-csi"
  volume_id    = "mailserver_out_queue[${count.index}]"
  name         = "mailserver_out_queue[${count.index}]"
  capacity_min = local.disk_min_size
  capacity_max = local.disk_max_size

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }

  parameters = {
    kadalu_format   = "native"
    storage_name    = "csi-pool"
    gluster_hosts   = "${local.gluster_env}-gluster01.example.org,${local.gluster_env}-gluster02.example.org,${local.gluster_env}-gluster03.example.org"
    gluster_volname = "csi"
  }
}

resource "nomad_job" "mailserver-in" {
  depends_on = [
    resource.nomad_csi_volume.mailserver_in_queue,
  ]
  hcl2 {
    vars = {
      nomad_env              = data.consul_keys.mailserver.var.nomad_env,
      url_prefix_env         = data.consul_keys.mailserver.var.url_prefix_env,
      docker_postfix_version = data.consul_keys.mailserver.var.docker_postfix_version,
      clamav_mirror          = data.consul_keys.mailserver.var.clamav_mirror,
      proxy_interfaces       = data.consul_keys.mailserver.var.proxy_interfaces,
      key_names              = data.consul_keys.mailserver.var.key_names,
      resource_count         = data.consul_keys.mailserver.var.resource_count,
      dkim_keys_prefix       = data.consul_keys.mailserver.var.dkim_keys_prefix,
      force_pull             = data.consul_keys.mailserver.var.force_pull,
      mynetworks             = data.consul_keys.mailserver.var.mynetworks,
      relay_domains          = data.consul_keys.mailserver.var.relay_domains,
      transport              = data.consul_keys.mailserver.var.transport,
    }
  }

  rerun_if_dead    = true
  purge_on_destroy = true
  jobspec          = file("${path.module}/mailserver-in.nomad")
}

resource "nomad_job" "mailserver-out" {
  depends_on = [
    resource.nomad_csi_volume.mailserver_out_queue,
  ]
  hcl2 {
    vars = {
      nomad_env              = data.consul_keys.mailserver.var.nomad_env,
      url_prefix_env         = data.consul_keys.mailserver.var.url_prefix_env,
      docker_postfix_version = data.consul_keys.mailserver.var.docker_postfix_version,
      clamav_mirror          = data.consul_keys.mailserver.var.clamav_mirror,
      out_proxy_interfaces   = data.consul_keys.mailserver.var.out_proxy_interfaces,
      key_names              = data.consul_keys.mailserver.var.key_names,
      resource_count         = data.consul_keys.mailserver.var.resource_count,
      dkim_keys_prefix       = data.consul_keys.mailserver.var.dkim_keys_prefix,
      force_pull             = data.consul_keys.mailserver.var.force_pull,
      mynetworks             = data.consul_keys.mailserver.var.mynetworks,
    }
  }

  rerun_if_dead    = true
  purge_on_destroy = true
  jobspec          = file("${path.module}/mailserver-out.nomad")
}
