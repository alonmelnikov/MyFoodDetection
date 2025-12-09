#!/bin/bash
# Strip resource forks from Flutter.framework before codesigning
set -e

FRAMEWORK_PATH="${BUILT_PRODUCTS_DIR}/Flutter.framework/Flutter"
if [ -f "$FRAMEWORK_PATH" ]; then
    echo "Stripping resource forks from Flutter.framework..."
    xattr -cr "$FRAMEWORK_PATH" 2>/dev/null || true
    # Remove any ._ files in the framework
    find "${BUILT_PRODUCTS_DIR}/Flutter.framework" -name "._*" -delete 2>/dev/null || true
    echo "✅ Resource forks removed"
fi
