#!/usr/bin/env zsh
# Sync Xcode's 'AdditionalDocumentation' (LLM-oriented Markdown) into THIS repo.
# Prefers /Applications/Xcode-beta.app, falls back to /Applications/Xcode.app.
# Output goes to: <repo>/docs/xcode/<version+build>/ ... and <repo>/docs/xcode/latest -> that folder.

set -e
set -u
set -o pipefail

# --- Xcode app locations ---
PREFERRED_APP="/Applications/Xcode-beta.app"
FALLBACK_APP="/Applications/Xcode.app"

# --- Resolve project root robustly ---
SCRIPT_PATH="${0:A}"          # absolute path to this script file
SCRIPT_DIR="${SCRIPT_PATH:h}" # directory containing this script

if [[ -n "${PROJECT_ROOT:-}" && -d "$PROJECT_ROOT" ]]; then
  REPO_ROOT="${PROJECT_ROOT:A}"
else
  if REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null)"; then
    :
  elif [[ "${SCRIPT_DIR:t}" == "scripts" ]]; then
    REPO_ROOT="${SCRIPT_DIR:h}"
  else
    REPO_ROOT="${SCRIPT_DIR:h}"
  fi
fi

# --- Destination inside repo ---
REPO_DOCS_DIR="${REPO_ROOT}/docs/xcode"
REPO_LATEST_LINK="${REPO_DOCS_DIR}/latest"
mkdir -p "$REPO_DOCS_DIR"

# --- Pick Xcode app ---
APP=""
if [[ -d "$PREFERRED_APP" ]]; then
  APP="$PREFERRED_APP"
elif [[ -d "$FALLBACK_APP" ]]; then
  APP="$FALLBACK_APP"
else
  print -u2 "❌ No Xcode app found at:
  $PREFERRED_APP
  $FALLBACK_APP"
  exit 1
fi

# --- Read version/build from Info.plist ---
INFO_PLIST="$APP/Contents/Info.plist"
VER=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$INFO_PLIST" 2>/dev/null || print -r -- "unknown")
BUILD=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$INFO_PLIST" 2>/dev/null || print -r -- "0")
STAMP="$(date +%Y%m%d-%H%M)"
VERSION_DIR="${REPO_DOCS_DIR}/${VER}+${BUILD}"
mkdir -p "$VERSION_DIR"

# --- Find all AdditionalDocumentation dirs ---
typeset -a DOC_DIRS
DOC_DIRS=($(find "$APP" -type d -name AdditionalDocumentation 2>/dev/null))

if (( ${#DOC_DIRS} == 0 )); then
  print -u2 "⚠️  No 'AdditionalDocumentation' directories found in: $APP"
  exit 0
fi

print "📚 Found ${#DOC_DIRS} AdditionalDocumentation dir(s) in: $APP"
print "📁 Project root resolved to: $REPO_ROOT"

# --- Stage copy in a temp dir, Markdown only ---
TMPDIR="$(mktemp -d)"
for d in "${DOC_DIRS[@]}"; do
  rel="${d#"$APP/"}"
  dest="$TMPDIR/$rel"
  mkdir -p "$dest"
  rsync -a --include='*/' --include='*.md' --exclude='*' "$d/" "$dest/"
done

# Manifest for provenance
{
  print "app_path: $APP"
  print "version: $VER"
  print "build: $BUILD"
  print "synced_at: $STAMP"
} > "$TMPDIR/manifest.txt"

# --- Copy into repo versioned dir & update 'latest' ---
rsync -a "$TMPDIR/" "$VERSION_DIR/"
rm -rf "$TMPDIR"

rm -f "$REPO_LATEST_LINK"
ln -s "$VERSION_DIR" "$REPO_LATEST_LINK"

print "✅ Synced to: $VERSION_DIR"
print "🔗 Latest -> $REPO_LATEST_LINK"

# --- Friendly summary ---
md_count=$(find "$REPO_LATEST_LINK" -type f -name '*.md' | wc -l | tr -d ' ')
print "ℹ️  Markdown files available to Claude (repo-local): $md_count"

# --- Add ignore rule (if not present) ---
IGNORE_LINE="docs/xcode/"
if [[ -f "$REPO_ROOT/.gitignore" ]]; then
  if ! grep -qxF "$IGNORE_LINE" "$REPO_ROOT/.gitignore" 2>/dev/null; then
    {
      print ""
      print "# Xcode AdditionalDocumentation (local-only)"
      print "$IGNORE_LINE"
    } >> "$REPO_ROOT/.gitignore"
    print "🧹 Added 'docs/xcode/' to .gitignore"
  fi
else
  print "⚠️  Consider adding 'docs/xcode/' to your .gitignore"
fi
