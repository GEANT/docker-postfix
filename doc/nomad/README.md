# Terraform/Nomad Module for the mailserver

## Preface

For this configuration we use the following technologies:

* Nomad
* Gluster storage with Kadalu CSI plugin
* Consul as a key store and DNS service discovery
* Vault as a secret store

For the automation we use Puppet and Terraform. With puppet we upload the keys onto Consul

Part of the keys are split per environment. Each environment name matches a workspace in terraform. For instance `test`, `uat` and `prod`.

## Diagram & Files

![Mail server Nomad Architecture](../.pics/mailserver_nomad.jpg?raw=true)

Files included in this example

doc
└─nomad
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└─[README.md](./README.md)
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└─[backend.tf](./backend.tf)
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└─[mailserver-in.nomad](./mailserver-in.nomad)
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└─[mailserver-out.nomad](./mailserver-out.nomad)
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└─[main.tf](./main.tf)

## DKIM Keys

the private Keys are listed in Consul as a JSON object:

```json
[
  "test-example-net.private",
  "test-lists-example-org.private",
  "test-lists-example-org.private",
  "test-lists-example-test-org.private",
  "test-test-host-example-org.private"
]
```

and they are pulled from Vault.

## ClamAV

ClamAV DB is pulled from scratch every time the container is rebuilt. We use an internal mirror, to avoid being banned and to speed up the readiness ot the container.

## Storage

There is only one volume on each container

* `mailserver_in_queue` (for the ingress mail server)
* `mailserver_out_queue` (for the egress mail server)

The storage is protected from destruction in the `main.tf`:

```hcl
  lifecycle {
    prevent_destroy = true
  }
```

## commands examples

Select an environment and apply a status

```bash
terraform select workspace test
terraform apply
```

destroying a resource

```bash
terraform apply -destroy -target=nomad_job.mailserver-out
```

:warning: It is mandatory to target a resource, because the storage is protected and destroying all the resources would fail
