#!/bin/zsh
set -e

SDK_PATH=$(xcrun --show-sdk-path)
BUILD_DIR=".build/bin"
CACHE_DIR="$PWD/.cache"

mkdir -p "$BUILD_DIR" "$CACHE_DIR/clang" "$CACHE_DIR/module" "$CACHE_DIR/sdk"

echo "==> Compiling MultitouchBridge..."
clang -c Sources/MultitouchBridge/MultitouchBridge.m \
  -isysroot "$SDK_PATH" \
  -I Sources/MultitouchBridge/include \
  -F /System/Library/PrivateFrameworks \
  -fmodules-cache-path="$CACHE_DIR/clang" \
  -o "$BUILD_DIR/MultitouchBridge.o"

echo "==> Compiling MagicTouch App..."
swiftc \
  -parse-as-library \
  -sdk "$SDK_PATH" \
  -module-cache-path "$CACHE_DIR/module" \
  -Xcc -fmodules-cache-path="$CACHE_DIR/clang" \
  -F /System/Library/PrivateFrameworks \
  -framework MultitouchSupport \
  -framework AppKit \
  -framework SwiftUI \
  -framework CoreGraphics \
  -I Sources/MultitouchBridge/include \
  "$BUILD_DIR/MultitouchBridge.o" \
  Sources/MagicTouch/Models/*.swift \
  Sources/MagicTouch/Engine/*.swift \
  Sources/MagicTouch/Store/*.swift \
  Sources/MagicTouch/Views/*.swift \
  Sources/MagicTouch/main.swift \
  -o "$BUILD_DIR/MagicTouch"

echo "==> Build successful: $BUILD_DIR/MagicTouch"
