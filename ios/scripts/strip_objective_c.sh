#!/bin/sh

# Strip debug symbols from objective_c.framework to prevent dSYM errors during Archive
FRAMEWORK_EXECUTABLE="${TARGET_BUILD_DIR}/${WRAPPER_NAME}/Frameworks/objective_c.framework/objective_c"

if [ -f "$FRAMEWORK_EXECUTABLE" ]; then
    echo "Stripping debug symbols from $FRAMEWORK_EXECUTABLE"
    strip -S "$FRAMEWORK_EXECUTABLE"
fi
