#!/bin/bash
set -e

# Version update helper script
# Usage: ./update_version.sh 1.2.0

if [ -z "$1" ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 1.2.0"
    exit 1
fi

NEW_VERSION=$1

# Validate version format
if ! [[ $NEW_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Version must be in format X.Y.Z (e.g., 1.2.0)"
    exit 1
fi

echo "Updating version to $NEW_VERSION..."

# Update config.yaml
sed -i.bak "s/^version: \".*\"/version: \"$NEW_VERSION\"/" config.yaml && rm config.yaml.bak
echo "✓ Updated config.yaml"

# Update config.json
sed -i.bak "s/\"version\": \".*\"/\"version\": \"$NEW_VERSION\"/" config.json && rm config.json.bak
echo "✓ Updated config.json"

echo ""
echo "Version updated to $NEW_VERSION"
echo ""
echo "Next steps:"
echo "1. Update CHANGELOG.md with release notes"
echo "2. Commit: git add config.yaml config.json CHANGELOG.md"
echo "3. Commit: git commit -m 'Bump version to $NEW_VERSION'"
echo "4. Push: git push origin main"
echo "5. Create release: https://github.com/atheismann/home-assistant-aurora-ruby-addon/releases/new"
echo "   - Tag: v$NEW_VERSION"
echo "   - Title: v$NEW_VERSION"
echo "   - Copy release notes from CHANGELOG.md"
