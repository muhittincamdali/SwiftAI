#!/usr/bin/env bash
# Renders the README images into docs/images.
#
# The images come from Tests/SwiftAITests/RenderTests.swift, which trains four classifiers on the
# iris petal measurements and draws their predictions with the view in
# Examples/ModelLab/ModelLab/DecisionBoundaries.swift (linked into the test target). Nothing is
# drawn by hand: every coloured cell is a model prediction.
#
# Usage: scripts/generate-images.sh   (macOS 13 or later)
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
output_dir="$repo_root/docs/images"
mkdir -p "$output_dir"

cd "$repo_root"
IMAGE_DIR="$output_dir" swift test --filter RenderTests
ls -1 "$output_dir"
