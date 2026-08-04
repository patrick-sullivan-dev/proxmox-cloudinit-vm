# Proxmox VM Module

## Dev checks

Run the checks from the repository root:

```shell
terraform fmt -check -recursive -diff
tflint --format=compact --no-color
terraform init -backend=false -input=false
terraform validate
```

Validate the Cloud-init templates with placeholder variables:

```shell
tests/template-validation/validate.sh
```

The template validator only renders files in a temp directory and deletes them when 
it exits. It only uses test inputs found in main.tf (in the same dir as this file).
It does not use any user defined variables. 

## Sensitive data

Cloud-init file content is stored in the caller's Terraform state and Proxmox
snippets datastore. This is senstive data. It is recommended that you use an 
encrypted remote state backend, restrict access to the snippets datastore, and 
avoid using user_data plaintext passwords unless needed, or if you just don't care. 
