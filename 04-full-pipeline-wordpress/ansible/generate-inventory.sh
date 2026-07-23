#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
terraform_dir="$script_dir/../terraform"

public_ip="$(terraform -chdir="$terraform_dir" output -raw public_ip)"

mkdir -p "$script_dir/inventory"
cat > "$script_dir/inventory/hosts.ini" <<EOF
[web]
$public_ip ansible_user=ubuntu ansible_python_interpreter=/usr/bin/python3.12
EOF

echo "Wrote inventory/hosts.ini for $public_ip"