#!/bin/bash
# One-time fix: install gems and pods with Ruby 2.6 so fastlane/pod work.
# Run from project root: ./ios/install_gems_and_pods.sh

set -e
# CocoaPods needs UTF-8 (avoids Encoding::CompatibilityError when run from Fastlane/CI)
export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Find rbenv (script may run from IDE or shell without rbenv in PATH)
for RBENV_ROOT in "$HOME/.rbenv" "/opt/homebrew/opt/rbenv" "/usr/local/opt/rbenv"; do
  if [ -x "$RBENV_ROOT/bin/rbenv" ]; then
    export PATH="$RBENV_ROOT/bin:$PATH"
    break
  fi
done

if ! command -v rbenv &>/dev/null; then
  echo "rbenv not found. Install with: brew install rbenv ruby-build && rbenv install 2.6.10"
  exit 1
fi

eval "$(rbenv init -)" 2>/dev/null || true

if ! ruby -e 'exit 1 unless RUBY_VERSION.start_with?("2.6")' 2>/dev/null; then
  echo "Ruby 2.6 not found. Run: rbenv install 2.6.10"
  exit 1
fi

RBENV_ROOT="$(rbenv root)"
# Prefer .ruby-version; fallback to rbenv version-name or 2.6.10
if [ -f "$SCRIPT_DIR/.ruby-version" ]; then
  RBENV_RUBY="$(cat "$SCRIPT_DIR/.ruby-version" | tr -d '\n')"
else
  RBENV_RUBY="$(rbenv version-name 2>/dev/null || true)"
fi
[ -z "$RBENV_RUBY" ] || [ "$RBENV_RUBY" = "system" ] && RBENV_RUBY="2.6.10"
RUBY26_BIN="$RBENV_ROOT/versions/${RBENV_RUBY}/bin"
RBENV_BUNDLE="$RUBY26_BIN/bundle"
# Force rbenv Ruby 2.6 and its gems only (no system / user gem dir → arm64 ffi)
export PATH="$RUBY26_BIN:${RBENV_ROOT}/shims:/usr/bin:/bin:/usr/sbin:/sbin"
export GEM_HOME="$RBENV_ROOT/versions/${RBENV_RUBY}/lib/ruby/gems/2.6.0"
export GEM_PATH="$GEM_HOME"

echo "Using $(ruby -v)"
echo "Running bundle install..."
"$RBENV_BUNDLE" install
echo "Running pod install with Ruby 2.6..."
"$RBENV_BUNDLE" exec pod install --repo-update
echo "Done. You can run ./ios/fastlane/fastlane_menu.sh now."
