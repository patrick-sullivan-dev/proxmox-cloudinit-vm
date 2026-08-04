#!/usr/bin/env bash

set -euo pipefail
umask 077

validation_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
temp_parent=${RUNNER_TEMP:-${TMPDIR:-/tmp}}
temp_parent=${temp_parent%/}
validation_temp=$(mktemp -d "${temp_parent}/proxmox-cloudinit-validation.XXXXXX")

cleanup() {
  case "$validation_temp" in
    "${temp_parent}"/proxmox-cloudinit-validation.*)
      rm -rf -- "$validation_temp"
      ;;
    *)
      printf 'Refusing to remove unexpected temporary path: %s\n' "$validation_temp" >&2
      ;;
  esac
}
trap cleanup EXIT HUP INT TERM

mkdir -p "$validation_temp/terraform-data"
printf '{}\n' >"$validation_temp/instance-data.json"

validate_cases() {
  local collection=$1
  local file_prefix=$2
  local schema_type=$3
  local case_name
  local rendered_cases
  local rendered_file
  local validation_output

  rendered_cases=$(
    printf 'jsonencode(%s)\n' "$collection" |
      TF_DATA_DIR="$validation_temp/terraform-data" \
        terraform -chdir="$validation_dir" console |
      jq -r .
  )

  if ! jq -e 'type == "object"' >/dev/null <<<"$rendered_cases"; then
    printf 'Terraform did not return the expected fixture collection.\n' >&2
    return 1
  fi

  while IFS= read -r case_name; do
    rendered_file="$validation_temp/${file_prefix}-${case_name}.yaml"
    jq -r --arg case_name "$case_name" '.[$case_name]' <<<"$rendered_cases" >"$rendered_file"

    if ! validation_output=$(
      cloud-init schema \
        --schema-type "$schema_type" \
        --config-file "$rendered_file" \
        --instance-data "$validation_temp/instance-data.json" \
        2>&1
    ); then
      printf 'Cloud-init validation failed for synthetic fixture %s.\n' "$case_name" >&2
      printf '%s\n' "$validation_output" >&2
      return 1
    fi

    printf 'Validated synthetic %s fixture: %s\n' "$schema_type" "$case_name"
  done < <(jq -r 'keys[]' <<<"$rendered_cases")
}

if [[ $# -eq 0 ]]; then
  set -- user-data network-data
fi

for target in "$@"; do
  case "$target" in
    user-data)
      validate_cases local.user_data_cases user-data cloud-config
      ;;
    network-data)
      validate_cases local.network_data_cases network-data network-config
      ;;
    *)
      printf 'Unknown validation target: %s\n' "$target" >&2
      exit 2
      ;;
  esac
done
