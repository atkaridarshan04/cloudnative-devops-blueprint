#!/bin/bash
# Usage: ./set-version.sh <version> <color>
# Example: ./set-version.sh 1.0.0 blue
#          ./set-version.sh 2.0.0 red
#          ./set-version.sh 3.0.0 purple

set -e

VERSION=$1
COLOR=$2

if [ -z "$VERSION" ] || [ -z "$COLOR" ]; then
  echo "Usage: $0 <version> <color>"
  echo "  version: 1.0.0 | 2.0.0 | 3.0.0"
  echo "  color:   blue | red | purple"
  exit 1
fi

FRONTEND_DIR="src/frontend/src/pages"
BACKEND_FILE="src/backend/index.js"

# Color mappings
case $COLOR in
  blue)   BG="blue-700";   HOVER="blue-500";   BORDER="blue-400"; BTN="blue-300" ;;
  red)    BG="red-700";    HOVER="red-500";    BORDER="red-400";  BTN="red-400"  ;;
  purple) BG="purple-700"; HOVER="purple-500"; BORDER="purple-400"; BTN="purple-300" ;;
  *)
    echo "Unknown color: $COLOR. Use blue | red | purple"
    exit 1
    ;;
esac

# Detect current color in Home.jsx to replace it
CURRENT_BG=$(grep -o 'bg-[a-z]*-700' "$FRONTEND_DIR/Home.jsx" | head -1)
CURRENT_COLOR=$(echo "$CURRENT_BG" | sed 's/bg-\([a-z]*\)-700/\1/')

case $CURRENT_COLOR in
  blue)   CUR_BG="blue-700";   CUR_HOVER="blue-500";   CUR_BORDER="blue-400"; CUR_BTN="blue-300" ;;
  red)    CUR_BG="red-700";    CUR_HOVER="red-500";    CUR_BORDER="red-400";  CUR_BTN="red-400"  ;;
  purple) CUR_BG="purple-700"; CUR_HOVER="purple-500"; CUR_BORDER="purple-400"; CUR_BTN="purple-300" ;;
  *)
    echo "Could not detect current color from Home.jsx"
    exit 1
    ;;
esac

# Detect current version
CURRENT_VERSION=$(grep -o 'v[0-9]*\.[0-9]*\.[0-9]*' "$FRONTEND_DIR/Home.jsx" | head -1 | tr -d 'v')

echo "Switching: v$CURRENT_VERSION ($CURRENT_COLOR) → v$VERSION ($COLOR)"

# Update Home.jsx
sed -i \
  "s/bg-$CUR_BG/bg-$BG/g; s/hover:bg-$CUR_HOVER/hover:bg-$HOVER/g; s/text-$CUR_BG/text-$BG/g; s/v$CURRENT_VERSION/v$VERSION/g" \
  "$FRONTEND_DIR/Home.jsx"

# Update Create/Edit forms
sed -i "s/border-$CUR_BORDER/border-$BORDER/g; s/bg-$CUR_BTN/bg-$BTN/g" \
  "$FRONTEND_DIR/CreateBooks.jsx" \
  "$FRONTEND_DIR/EditBook.jsx"

# Update backend
sed -i "s/v$CURRENT_VERSION/v$VERSION/" "$BACKEND_FILE"

echo "Done. Now build:"
echo "  docker build -t ghcr.io/atkaridarshan04/cloudnative-devops-blueprint/bookstore-frontend:$VERSION src/frontend/"
echo "  docker build -t ghcr.io/atkaridarshan04/cloudnative-devops-blueprint/bookstore-backend:$VERSION src/backend/"
