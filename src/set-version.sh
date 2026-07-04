#!/usr/bin/env bash

# Usage:
# ./set-version.sh 1.0.0 blue
# ./set-version.sh 2.0.0 red
# ./set-version.sh 3.0.0 purple

set -euo pipefail

VERSION="${1:-}"
COLOR="${2:-}"

if [[ -z "$VERSION" || -z "$COLOR" ]]; then
    echo "Usage: $0 <version> <color>"
    echo "Versions: 1.0.0 | 2.0.0 | 3.0.0"
    echo "Colors:   blue | red | purple"
    exit 1
fi

FRONTEND_DIR="src/frontend/src/pages"
BACKEND_FILE="src/backend/index.js"

# Cross-platform sed
if [[ "$OSTYPE" == "darwin"* ]]; then
    SED_CMD=(sed -i '')
else
    SED_CMD=(sed -i)
fi

# Target colors
case "$COLOR" in
    blue)
        BG="blue-700"
        HOVER="blue-500"
        BORDER="blue-400"
        BTN="blue-300"
        ;;
    red)
        BG="red-700"
        HOVER="red-500"
        BORDER="red-400"
        BTN="red-400"
        ;;
    purple)
        BG="purple-700"
        HOVER="purple-500"
        BORDER="purple-400"
        BTN="purple-300"
        ;;
    *)
        echo "Unknown color: $COLOR"
        echo "Use: blue | red | purple"
        exit 1
        ;;
esac

HOME_FILE="$FRONTEND_DIR/Home.jsx"

if [[ ! -f "$HOME_FILE" ]]; then
    echo "File not found: $HOME_FILE"
    exit 1
fi

# Detect current version
CURRENT_VERSION=$(
    grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' "$HOME_FILE" \
    | head -1 \
    | sed 's/^v//'
)

if [[ -z "$CURRENT_VERSION" ]]; then
    echo "Could not detect current version"
    exit 1
fi

# Detect current color
CURRENT_COLOR=$(
    grep -oE 'bg-(blue|red|purple)-700' "$HOME_FILE" \
    | head -1 \
    | cut -d'-' -f2
)

if [[ -z "$CURRENT_COLOR" ]]; then
    echo "Could not detect current color"
    exit 1
fi

case "$CURRENT_COLOR" in
    blue)
        CUR_BG="blue-700"
        CUR_HOVER="blue-500"
        CUR_BORDER="blue-400"
        CUR_BTN="blue-300"
        ;;
    red)
        CUR_BG="red-700"
        CUR_HOVER="red-500"
        CUR_BORDER="red-400"
        CUR_BTN="red-400"
        ;;
    purple)
        CUR_BG="purple-700"
        CUR_HOVER="purple-500"
        CUR_BORDER="purple-400"
        CUR_BTN="purple-300"
        ;;
    *)
        echo "Unsupported detected color: $CURRENT_COLOR"
        exit 1
        ;;
esac

echo "Switching: v${CURRENT_VERSION} (${CURRENT_COLOR}) → v${VERSION} (${COLOR})"

# Home.jsx
"${SED_CMD[@]}" \
-e "s/bg-$CUR_BG/bg-$BG/g" \
-e "s/hover:bg-$CUR_HOVER/hover:bg-$HOVER/g" \
-e "s/text-$CUR_BG/text-$BG/g" \
-e "s/v$CURRENT_VERSION/v$VERSION/g" \
"$HOME_FILE"

# CreateBooks.jsx
if [[ -f "$FRONTEND_DIR/CreateBooks.jsx" ]]; then
    "${SED_CMD[@]}" \
    -e "s/border-$CUR_BORDER/border-$BORDER/g" \
    -e "s/bg-$CUR_BTN/bg-$BTN/g" \
    "$FRONTEND_DIR/CreateBooks.jsx"
fi

# EditBook.jsx
if [[ -f "$FRONTEND_DIR/EditBook.jsx" ]]; then
    "${SED_CMD[@]}" \
    -e "s/border-$CUR_BORDER/border-$BORDER/g" \
    -e "s/bg-$CUR_BTN/bg-$BTN/g" \
    "$FRONTEND_DIR/EditBook.jsx"
fi

# Backend
if [[ -f "$BACKEND_FILE" ]]; then
    "${SED_CMD[@]}" \
    -e "s/v$CURRENT_VERSION/v$VERSION/g" \
    "$BACKEND_FILE"
fi

echo ""
echo "✅ Done"
echo ""
echo "Frontend image:"
echo "docker buildx build \\"
echo "  --platform linux/amd64,linux/arm64 \\"
echo "  -t ghcr.io/atkaridarshan04/cloudnative-devops-blueprint/bookstore-frontend:$VERSION \\"
echo "  --push src/frontend/"
echo ""
echo "Backend image:"
echo "docker buildx build \\"
echo "  --platform linux/amd64,linux/arm64 \\"
echo "  -t ghcr.io/atkaridarshan04/cloudnative-devops-blueprint/bookstore-backend:$VERSION \\"
echo "  --push src/backend/"
