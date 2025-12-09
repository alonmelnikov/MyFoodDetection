#!/bin/bash
# Fix resource forks on Flutter.framework before codesigning

FLUTTER_FRAMEWORK_PATH="${TARGET_BUILD_DIR}/Flutter.framework/Flutter"

if [ -f "$FLUTTER_FRAMEWORK_PATH" ]; then
    echo "Stripping resource forks from Flutter.framework..."
    xattr -cr "$FLUTTER_FRAMEWORK_PATH" 2>/dev/null || true
    # Also try to remove any ._ files
    find "${TARGET_BUILD_DIR}/Flutter.framework" -name "._*" -delete 2>/dev/null || true
    echo "Resource forks removed"
fi
