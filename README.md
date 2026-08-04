# Proxmox VM Module

## Development checks

Run the Terraform checks from the repository root:

```shell
terraform fmt -check -recursive -diff
tflint --format=compact --no-color
terraform init -backend=false -input=false
terraform validate
```

Validate the Cloud-init templates with synthetic, non-secret fixtures:

```shell
tests/template-validation/validate.sh
```

The template validator creates files only in a permission-restricted temporary
directory and removes them when it exits. It does not use module inputs or real
infrastructure values.

## Sensitive data

Custom Cloud-init content is stored in the caller's Terraform state and Proxmox
snippets datastore. Protect both as sensitive data. Use an encrypted remote
state backend with least-privilege access, restrict access to the snippets
datastore, and avoid plaintext passwords where possible.

The optional `debug_files` input writes rendered Cloud-init files to disk and is
disabled by default. Do not enable it on shared or untrusted systems.
