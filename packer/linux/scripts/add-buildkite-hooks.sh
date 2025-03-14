#!/bin/bash

# Script to add environment hooks for AWS SSM and ECR Plugins
set -euo pipefail

# Create directories
SSM_HOOKS_DIR="/usr/local/buildkite-aws-stack/plugins/secrets/hooks"
ECR_HOOKS_DIR="/usr/local/buildkite-aws-stack/plugins/ecr/hooks"
sudo mkdir -p "${SSM_HOOKS_DIR}" "${ECR_HOOKS_DIR}"

# Create SSM environment hook
cat << 'EOF' | sudo tee "${SSM_HOOKS_DIR}/environment"
#!/bin/bash
set -euo pipefail

echo "AWS SSM Plugin environment hook loaded"
EOF

# Create ECR environment hook
cat << 'EOF' | sudo tee "${ECR_HOOKS_DIR}/environment"
#!/bin/bash
set -euo pipefail

echo "AWS ECR Plugin environment hook loaded"

if [[ "${BUILDKITE_PLUGIN_ECR_LOGIN:-}" == "1" ]]; then
    echo "~~~ Logging in to ECR"
    aws ecr get-login-password --region "${BUILDKITE_AGENT_META_DATA_AWS_REGION}" | docker login --username AWS --password-stdin "${BUILDKITE_AGENT_META_DATA_AWS_ACCOUNT_ID}.dkr.ecr.${BUILDKITE_AGENT_META_DATA_AWS_REGION}.amazonaws.com"
fi
EOF

# Set permissions
sudo chmod +x "${SSM_HOOKS_DIR}/environment" "${ECR_HOOKS_DIR}/environment"
sudo chown -R buildkite-agent:buildkite-agent "${SSM_HOOKS_DIR}" "${ECR_HOOKS_DIR}"

# Restart buildkite-agent
sudo systemctl restart buildkite-agent

echo "✅ Hooks created and configured:"
echo "   - SSM: ${SSM_HOOKS_DIR}/environment"
echo "   - ECR: ${ECR_HOOKS_DIR}/environment"

