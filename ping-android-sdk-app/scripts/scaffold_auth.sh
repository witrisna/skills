#!/usr/bin/env bash
#
# Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
#
# This software may be modified and distributed under the terms
# of the MIT license. See the LICENSE file for details.
#

# =============================================================================
# scaffold_auth.sh
#
# Scaffolds the authentication feature files from the my-skill/assets templates
# into a target Android module.
#
# Usage:
#   chmod +x my-skill/scripts/scaffold_auth.sh
#   ./my-skill/scripts/scaffold_auth.sh \
#       --package   com.example.myapp \
#       --src-dir   app/src/main/java \
#       --journey   Login
#
# Options:
#   --package    Base package name of your app (e.g. com.example.myapp)
#   --src-dir    Path to the Java/Kotlin source root (default: app/src/main/java)
#   --journey    Default journey/tree name to start (default: Login)
#   --help       Show this help message
# =============================================================================

set -euo pipefail

# ── Defaults ──────────────────────────────────────────────────────────────────
PACKAGE=""
SRC_DIR="app/src/main/java"
JOURNEY_NAME="Login"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$SCRIPT_DIR/../assets"

# ── Argument parsing ──────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --package)   PACKAGE="$2";      shift 2 ;;
        --src-dir)   SRC_DIR="$2";      shift 2 ;;
        --journey)   JOURNEY_NAME="$2"; shift 2 ;;
        --help)
            sed -n '2,25p' "$0"
            exit 0
            ;;
        *)
            echo "❌  Unknown option: $1"
            exit 1
            ;;
    esac
done

# ── Validation ────────────────────────────────────────────────────────────────
if [[ -z "$PACKAGE" ]]; then
    echo "❌  --package is required.  Example: --package com.example.myapp"
    exit 1
fi

# ── Derived paths ─────────────────────────────────────────────────────────────
PACKAGE_PATH="${PACKAGE//./\/}"
AUTH_DIR="$SRC_DIR/$PACKAGE_PATH/auth"
CALLBACK_DIR="$AUTH_DIR/callback"

# ── Helper: copy + replace placeholder ───────────────────────────────────────
copy_template() {
    local template="$1"
    local dest="$2"

    if [[ ! -f "$template" ]]; then
        echo "⚠️   Template not found: $template — skipping."
        return
    fi

    if [[ -f "$dest" ]]; then
        echo "⏭️   Already exists, skipping: $dest"
        return
    fi

    mkdir -p "$(dirname "$dest")"
    # Replace placeholder package and journey name
    sed \
        -e "s|com\.example\.myapp|$PACKAGE|g" \
        -e "s|\"Login\"|\"$JOURNEY_NAME\"|g" \
        "$template" > "$dest"

    echo "✅  Created: $dest"
}

# ── Scaffold files ────────────────────────────────────────────────────────────
echo ""
echo "🚀  Scaffolding Ping Identity Journey authentication feature..."
echo "    Package  : $PACKAGE"
echo "    Src dir  : $SRC_DIR"
echo "    Journey  : $JOURNEY_NAME"
echo ""

copy_template "$ASSETS_DIR/JourneyConfig.kt.template"  "$AUTH_DIR/JourneyConfig.kt"
copy_template "$ASSETS_DIR/AuthState.kt.template"       "$AUTH_DIR/AuthState.kt"
copy_template "$ASSETS_DIR/AuthViewModel.kt.template"   "$AUTH_DIR/AuthViewModel.kt"
copy_template "$ASSETS_DIR/AuthScreen.kt.template"      "$AUTH_DIR/AuthScreen.kt"
copy_template "$ASSETS_DIR/CallbackNode.kt.template"    "$CALLBACK_DIR/CallbackNode.kt"
copy_template "$ASSETS_DIR/CallbackFields.kt.template"  "$CALLBACK_DIR/CallbackFields.kt"

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "✨  Done!  Next steps:"
echo ""
echo "   1. Open $AUTH_DIR/JourneyConfig.kt and fill in your"
echo "      PingOne AIC server URL, realm, clientId, and discoveryEndpoint."
echo ""
echo "   2. Add the Journey SDK dependency to your build.gradle.kts:"
echo "      implementation(\"com.pingidentity.sdks:journey:<version>\")"
echo ""
echo "   3. Add the redirect URI intent-filter to your AndroidManifest.xml."
echo "      See my-skill/references/oidc-config.md for the snippet."
echo ""
echo "   4. Wire AuthScreen into your NavHost:"
echo "      composable(\"auth\") {"
echo "          AuthScreen(journeyName = \"$JOURNEY_NAME\") {"
echo "              navController.navigate(\"home\")"
echo "          }"
echo "      }"
echo ""

