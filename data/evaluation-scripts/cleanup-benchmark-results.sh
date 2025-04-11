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
rm -f data/metrics/*.{csv,txt}

# Remove logs
rm -f data/logs/*

echo "✅ Cleanup complete."
