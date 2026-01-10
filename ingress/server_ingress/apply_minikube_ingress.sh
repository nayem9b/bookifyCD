#!/usr/bin/env bash
set -euo pipefail

# Helper to apply ingress manifests for Minikube local testing
# Replaces MINIKUBE_IP placeholder in the YAMLs with `minikube ip` and applies them.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS=("${SCRIPT_DIR}/ingress_pointing_to_main.yaml" "${SCRIPT_DIR}/ingress_pointing_to_canary.yaml")

function ensure_minikube() {
  if ! command -v minikube >/dev/null 2>&1; then
    echo "minikube not found in PATH. Please install minikube and start the cluster." >&2
    exit 1
  fi
}

function ensure_kubectl() {
  if ! command -v kubectl >/dev/null 2>&1; then
    echo "kubectl not found in PATH. Please install kubectl." >&2
    exit 1
  fi
}

ensure_minikube
ensure_kubectl

echo "Enabling minikube ingress addon (may take a few seconds)..."
minikube addons enable ingress || true

MINIKUBE_IP=$(minikube ip)
if [ -z "$MINIKUBE_IP" ]; then
  echo "Failed to obtain Minikube IP." >&2
  exit 1
fi

echo "Using Minikube IP: $MINIKUBE_IP"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

for f in "${MANIFESTS[@]}"; do
  if [ ! -f "$f" ]; then
    echo "Manifest not found: $f" >&2
    exit 1
  fi
  out="$TMPDIR/$(basename "$f")"
  echo "Preparing $out"
  # Replace literal MINIKUBE_IP token with actual IP
  sed "s/MINIKUBE_IP/${MINIKUBE_IP}/g" "$f" > "$out"
done

echo "Applying manifests to cluster..."
kubectl apply -f "$TMPDIR/"

echo "Done. To test:
  - Main app:   http://bookify.${MINIKUBE_IP}.nip.io/
  - Canary API: http://api.bookify.${MINIKUBE_IP}.nip.io/

Use curl or open in a browser. Example:
  curl -v http://bookify.${MINIKUBE_IP}.nip.io/
"

exit 0
