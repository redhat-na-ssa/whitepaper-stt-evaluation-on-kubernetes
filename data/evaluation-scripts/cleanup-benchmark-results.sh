#!/bin/bash

###############################################################################
# Cleanup Script for Whisper Benchmark Outputs
#
# Removes:
#   - All .csv and .txt files from data/metrics/
#   - All logs from data/logs/
#
# USAGE:
#   ./cleanup-benchmark-results.sh
###############################################################################

set -e

echo "🧹 Cleaning up benchmark results..."

# Remove metrics CSVs and transcripts
rm -f data/metrics/$INSTANCE/$FLAVOR/*.{csv,txt}
rm -f data/metrics/*.{csv,txt}

# Delete unused Podman images
#podman image prune -a

# Clear unused container volumes
#podman volume prune

# Clear /var/tmp, /tmp, and logs
sudo rm -rf /var/tmp/*
sudo rm -rf /tmp/*
sudo journalctl --vacuum-time=1d

echo "✅ Cleanup complete."
