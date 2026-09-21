#!/bin/zsh
set -e

# ==============================================================================
# MagicTouch Automated Release Script
# Usage:
#   ./release.sh           (defaults to bumping patch: 0.1.1 -> 0.1.2)
#   ./release.sh patch     (e.g. 0.1.1 -> 0.1.2)
#   ./release.sh minor     (e.g. 0.1.1 -> 0.2.0)
#   ./release.sh major     (e.g. 0.1.1 -> 1.0.0)
#   ./release.sh 0.2.0     (explicit target version)
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# 1. Ensure working directory is clean
if [ -n "$(git status --porcelain)" ]; then
    echo "❌ Error: Working directory has uncommitted changes."
    echo "Please commit or stash your changes before running release.sh."
    exit 1
fi

# 2. Ensure on main branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo "⚠️ Warning: Currently on branch '$CURRENT_BRANCH'. Switching to 'main'..."
    git checkout main
fi

# 3. Pull latest changes
echo "==> Pulling latest changes from origin/main..."
git pull origin main

# 4. Determine current version from UpdateChecker.swift
VERSION_FILE="Sources/MagicTouch/Engine/UpdateChecker.swift"
CURRENT_VERSION=$(grep -E '@Published public var currentVersion: String =' "$VERSION_FILE" | sed -E 's/.*"([^"]+)".*/\1/')
if [ -z "$CURRENT_VERSION" ]; then
    echo "❌ Error: Could not determine current version from $VERSION_FILE."
    exit 1
fi
echo "📌 Current version: $CURRENT_VERSION"

TARGET="${1:-patch}"
NEXT_VERSION=""

if [[ "$TARGET" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+.*$ ]]; then
    NEXT_VERSION="${TARGET#v}"
else
    IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"
    PATCH_NUM="${PATCH%%-*}"

    case "$TARGET" in
        patch)
            NEXT_VERSION="$MAJOR.$MINOR.$((PATCH_NUM + 1))"
            ;;
        minor)
            NEXT_VERSION="$MAJOR.$((MINOR + 1)).0"
            ;;
        major)
            NEXT_VERSION="$((MAJOR + 1)).0.0"
            ;;
        *)
            echo "❌ Error: Invalid argument '$TARGET'."
            echo "Usage: ./release.sh [patch | minor | major | X.Y.Z]"
            exit 1
            ;;
    esac
fi

NEW_TAG="v$NEXT_VERSION"
echo "🚀 Preparing release for: $NEW_TAG (version: $NEXT_VERSION)"

# Check if tag already exists locally or remotely
if git rev-parse "$NEW_TAG" >/dev/null 2>&1; then
    echo "❌ Error: Git tag '$NEW_TAG' already exists locally."
    exit 1
fi
if git ls-remote --tags origin "$NEW_TAG" | grep -q "$NEW_TAG"; then
    echo "❌ Error: Git tag '$NEW_TAG' already exists on remote 'origin'."
    exit 1
fi

# 5. Run automated test suite
echo "==> [1/5] Running automated test suite..."
./run_tests.sh

# 6. Update version in UpdateChecker.swift
echo "==> [2/5] Updating version in $VERSION_FILE..."
sed -i '' -E "s/@Published public var currentVersion: String = \".*\"/@Published public var currentVersion: String = \"$NEXT_VERSION\"/" "$VERSION_FILE"

# 7. Compile local build
echo "==> [3/5] Building application..."
./build.sh

# 8. Extract recent commit log for release notes
echo "==> [4/5] Generating release changelog..."
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
if [ -n "$LAST_TAG" ]; then
    CHANGELOG=$(git log "$LAST_TAG..HEAD" --oneline --no-merges || true)
fi
if [ -z "$CHANGELOG" ]; then
    CHANGELOG=$(git log -5 --oneline --no-merges)
fi

# 9. Commit, tag, and push
echo "==> [5/5] Committing, tagging, and pushing to GitHub..."
git add "$VERSION_FILE"
git commit -m "chore(release): bump version to $NEW_TAG"

TAG_MESSAGE=$(cat <<EOF
MagicTouch $NEW_TAG

Changelog:
$CHANGELOG
EOF
)

git tag -a "$NEW_TAG" -m "$TAG_MESSAGE"

echo "==> Pushing commits to origin/main..."
git push origin main

echo "==> Pushing tag $NEW_TAG to trigger GitHub Actions release pipeline..."
git push origin "$NEW_TAG"

echo "=========================================================="
echo "🎉 Successfully released $NEW_TAG!"
echo "GitHub Actions CI/CD has started packaging the Universal app,"
echo "creating the DMG installer, and generating latest.json."
echo "Track progress at:"
echo "  https://github.com/namikemen/magictouch/actions"
echo "Release will be published to:"
echo "  https://github.com/namikemen/magictouch/releases/tag/$NEW_TAG"
echo "=========================================================="
