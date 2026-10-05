#!/usr/bin/env bash
# ============================================================================
# tello_swarm installer for Raspberry Pi OS (and other Debian-based systems)
#
# One line:
#   curl -fsSL https://raw.githubusercontent.com/zoolfahmy/Drone-Computer-Vision-Distributed-Control-Swarm/main/install.sh | bash
#
# What it does:
#   1. installs git and python3-venv with apt, only if they are missing
#   2. puts the course files in ~/tello_swarm
#        - no folder yet        -> installs everything
#        - a clone of this repo -> git pull
#        - any other folder     -> adds the missing files, replaces shared_vision,
#                                  and keeps every other file you already have
#      The repository may hold the files themselves, or only
#      tello_swarm_task_files.zip: the installer handles both.
#   3. creates the Python environment ~/tello_swarm/swarm_env
#      (OpenCV, NumPy, djitellopy) and checks that it imports
#
# It never touches practical02/arena_homography.npy, your logs or swarm_env
# packages you installed yourself.
#
# Options (environment variables):
#   TELLO_SWARM_DIR=/path        install somewhere else   (default ~/tello_swarm)
#   TELLO_SWARM_BRANCH=name      another branch           (default main)
#   TELLO_SWARM_REPO=url         another repository
#   TELLO_SWARM_SKIP_ENV=1       files only, no Python environment
# Example:
#   curl -fsSL <url>/install.sh | TELLO_SWARM_SKIP_ENV=1 bash
# ============================================================================
set -euo pipefail

REPO_URL="${TELLO_SWARM_REPO:-https://github.com/zoolfahmy/Drone-Computer-Vision-Distributed-Control-Swarm.git}"
BRANCH="${TELLO_SWARM_BRANCH:-main}"
DEST="${TELLO_SWARM_DIR:-$HOME/tello_swarm}"
SKIP_ENV="${TELLO_SWARM_SKIP_ENV:-0}"
TMP_DIR=""
ZIP_NAME="tello_swarm_task_files.zip"

# Files that always follow the repository, even in a folder that already exists.
ALWAYS_REPLACE_DIRS="shared_vision"
ALWAYS_REPLACE_FILES="README.md TASK_FILES.txt install.sh requirements.txt .gitignore"

say()  { printf '\n==> %s\n' "$*"; }
note() { printf '    %s\n' "$*"; }
die()  { printf '\n[ERROR] %s\n' "$*" >&2; exit 1; }

need_packages() {
    local missing=""
    command -v git >/dev/null 2>&1 || missing="$missing git"
    command -v python3 >/dev/null 2>&1 || missing="$missing python3"
    if [ "$SKIP_ENV" != "1" ] && command -v python3 >/dev/null 2>&1; then
        python3 -c "import venv, ensurepip" >/dev/null 2>&1 || missing="$missing python3-venv"
    fi
    [ -z "$missing" ] && return 0

    say "Installing system packages:$missing"
    command -v apt-get >/dev/null 2>&1 || die "Please install these yourself, then run again:$missing"
    local sudo=""
    [ "$(id -u)" -eq 0 ] || sudo="sudo"
    $sudo apt-get update
    # shellcheck disable=SC2086
    $sudo apt-get install -y $missing
}

always_replace() {            # $1 = path relative to the repository root
    local rel="$1" d f
    for d in $ALWAYS_REPLACE_DIRS; do
        case "$rel" in "$d"/*) return 0 ;; esac
    done
    for f in $ALWAYS_REPLACE_FILES; do
        [ "$rel" = "$f" ] && return 0
    done
    return 1
}

merge_into_existing() {       # $1 = fresh clone, $2 = existing folder
    local src="$1" dst="$2" rel added=0 replaced=0 kept=0 same=0
    while IFS= read -r -d '' file; do
        rel="${file#"$src"/}"
        mkdir -p "$dst/$(dirname "$rel")"
        if [ ! -e "$dst/$rel" ]; then
            cp -p "$file" "$dst/$rel"; added=$((added + 1))
        elif cmp -s "$file" "$dst/$rel"; then
            same=$((same + 1))
        elif always_replace "$rel"; then
            cp -p "$file" "$dst/$rel"; replaced=$((replaced + 1))
        else
            kept=$((kept + 1))
            note "kept your version: $rel"
        fi
    done < <(find "$src" -path "$src/.git" -prune -o -type f -print0)
    note "$added added, $replaced replaced, $same already up to date, $kept kept as they were"
}

main() {
    need_packages

    TMP_DIR="$(mktemp -d)"
    trap 'rm -rf "${TMP_DIR:-}"' EXIT
    local tmp="$TMP_DIR"

    if [ -d "$DEST/.git" ]; then
        say "Updating $DEST (git pull)"
        if ! git -C "$DEST" pull --ff-only origin "$BRANCH"; then
            note "git pull did not finish (local changes?). The files were left as they are."
        fi
    else
        say "Downloading the course files"
        git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$tmp/src"
        local src="$tmp/src" from_zip=0
        if [ ! -d "$src/shared_vision" ] && [ -f "$src/$ZIP_NAME" ]; then
            note "unpacking $ZIP_NAME"
            python3 -m zipfile -e "$src/$ZIP_NAME" "$tmp/unzipped"
            src="$tmp/unzipped/tello_swarm"
            from_zip=1
        fi
        [ -d "$src/shared_vision" ] || die "The repository holds neither the course files nor $ZIP_NAME."

        if [ ! -e "$DEST" ]; then
            mkdir -p "$(dirname "$DEST")"
            if [ "$from_zip" = "1" ]; then
                mkdir -p "$DEST"
                cp -a "$src/." "$DEST/"
            else
                mv "$src" "$DEST"
            fi
            note "installed in $DEST"
        elif [ -d "$DEST" ]; then
            say "$DEST already exists: adding to it without overwriting your files"
            merge_into_existing "$src" "$DEST"
        else
            die "$DEST exists and is not a folder."
        fi
    fi

    if [ "$SKIP_ENV" = "1" ]; then
        say "Python environment skipped (TELLO_SWARM_SKIP_ENV=1)"
    else
        local env_dir="$DEST/swarm_env"
        if [ ! -x "$env_dir/bin/python" ]; then
            say "Creating the Python environment swarm_env"
            python3 -m venv "$env_dir"
        else
            say "Python environment swarm_env already exists"
        fi
        say "Installing Python packages (OpenCV, NumPy, djitellopy)"
        "$env_dir/bin/python" -m pip install --upgrade pip >/dev/null 2>&1 || true
        "$env_dir/bin/python" -m pip install -r "$DEST/requirements.txt"

        say "Checking the environment"
        "$env_dir/bin/python" - <<'PY'
import cv2, numpy, djitellopy
cv2.aruco.ArucoDetector          # needs OpenCV 4.7 or later
print("    OpenCV", cv2.__version__, "| NumPy", numpy.__version__, "| djitellopy imported")
PY
    fi

    cat <<EOF

============================================================
 tello_swarm is ready in $DEST
============================================================
 Every session:
     cd $DEST
     source swarm_env/bin/activate

 Camera Pi (after calibrating the arena, PW1 Task 5):
     python shared_vision/camera_host.py

 Each group's Pi:
     python shared_vision/vision_client.py                   # link check
     python shared_vision/fly_step10.py --sim --marker 1     # dry run, no drone

 Task list: $DEST/TASK_FILES.txt      Guide: $DEST/README.md
EOF
}

main "$@"
