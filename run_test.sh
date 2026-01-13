#!/usr/bin/env bash
set -euo pipefail

# Run a set of Nextflow integration tests for nf-core/isoseq
# Activates the `nextflow` mamba environment before invoking nextflow

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "== Activate mamba environment and run Nextflow tests =="

mamba_hook_shell="bash"
echo "Activating mamba ($mamba_hook_shell hook) and activating 'nextflow' environment..."
set +u
eval "$(mamba shell hook --shell zsh)"
mamba activate nextflow
set -u

if ! command -v nextflow >/dev/null 2>&1; then
  echo "❌ nextflow not found in PATH after activating environment"
  exit 1
fi

echo "nextflow: $(nextflow -version 2>&1 | head -n1)"

declare -a CMDS=(
    "nextflow run main.nf -profile docker -c conf/test_local.config --outdir testdata_results/test"
)

for CMD in "${CMDS[@]}"; do
  echo ""
  echo "=========================================================="
  echo "Running: $CMD"
  echo "=========================================================="
  eval "$CMD"
  echo "Finished: $CMD"
done

echo "All requested Nextflow tests completed."
