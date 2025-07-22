#!/bin/bash
show_about() {
  echo "🌲 tree-lite: A lightweight Bash file tree viewer"
  echo "📍 Location: $SCRIPT_PATH"
  echo "🛠  Author: Sḱreieweydō"
  echo "🔧 Features: colors, icons, sizes, exclusions, Markdown-friendly output"
  echo "ℹ️  Run './tree-lite.sh --help' for full usage"
}

set -euo pipefail

RESET="\033[0m"
BOLD="\033[1m"
FOLDER_ICON="📁"
FILE_ICON="📄"
declare_icon() {
  ext="$1"
  case "$ext" in
    ts) echo "🟦";;
    js) echo "🟨";;
    py) echo "🐍";;
    sh) echo "📜";;
    md) echo "📘";;
    pas) echo "🟪";;
    asm|s) echo "⚙️";;
    png|jpg|jpeg|gif|webp) echo "🖼️";;
    svg|ico|icns) echo "🎨";;
    html|htm) echo "🌐";;
    css) echo "🎀";;
    json|yml|yaml|toml) echo "📦";;
    pdf) echo "📄";;
    txt|log) echo "📝";;
    *) echo "$FILE_ICON";;
  esac
}

SCRIPT_PATH="$(cd "$(dirname "$0")"; pwd)/$(basename "$0")"
for arg in "$@"; do
  if [ "$arg" = "--about" ] || [ "$arg" = "-a" ]; then
    show_about
    exit 0
  fi
done

SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
SCRIPT_NAME="$(basename "$0")"
EXCLUDES=(".git" "node_modules" "$SCRIPT_NAME")
SHOW_HIDDEN=false
DEPTH_LIMIT=0
SHOW_ICONS=false
SHOW_SIZES=false
SHOW_HELP=false
DIRS_ONLY=false
FILES_ONLY=false
ONLY_EXT=""
MATCH_PATTERN=""
SORT_METHOD="name"
NO_COLOR=false
DIR_FIRST=false
MARKDOWN=false
SHOW_PERMS=false
SHOW_OWNERS=false
SHOW_MTIME=false
SUMMARY=false

file_count=0
dir_count=0
total_bytes=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --exclude) IFS=',' read -ra ADD_EXCLUDES <<< "$2"; EXCLUDES+=("${ADD_EXCLUDES[@]}"); shift 2 ;;
    --show-hidden) SHOW_HIDDEN=true; shift ;;
    --depth) DEPTH_LIMIT="$2"; shift 2 ;;
    --icons) SHOW_ICONS=true; shift ;;
    --sizes) SHOW_SIZES=true; shift ;;
    --dirs-only) DIRS_ONLY=true; shift ;;
    --files-only) FILES_ONLY=true; shift ;;
    --only-ext) ONLY_EXT="$2"; shift 2 ;;
    --match) MATCH_PATTERN="$2"; shift 2 ;;
    --sort) SORT_METHOD="$2"; shift 2 ;;
    --no-color) NO_COLOR=true; shift ;;
    --dir-first) DIR_FIRST=true; shift ;;
    --markdown) MARKDOWN=true; shift ;;
    --perms) SHOW_PERMS=true; shift ;;
    --owners) SHOW_OWNERS=true; shift ;;
    --mtime) SHOW_MTIME=true; shift ;;
    --summary) SUMMARY=true; shift ;;
    --help|-h) SHOW_HELP=true; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if [ "$SHOW_HELP" = true ]; then
  echo -e "
${BOLD}Usage:${RESET} $SCRIPT_NAME [options]

${BOLD}Options:${RESET}
  --exclude name1,name2,...   Exclude files or directories
  --show-hidden               Include dotfiles
  --depth N                   Limit depth
  --icons                     Show file/folder icons (uses emoji per type)
  --sizes                     Show file sizes
  --dirs-only                 Show only directories
  --files-only                Show only files
  --only-ext ext1,ext2        Only show specific extensions
  --match substring           Only show paths containing substring
  --sort name|size|time       Sort output
  --no-color                  Disable colors
  --dir-first                 Show directories before files
  --markdown                  Output as Markdown
  --perms                     Show permissions
  --owners                    Show owner/group
  --mtime                     Show last modified time
  --summary                   Print summary at the end
  --help, -h                  Show this help
"
  exit 0
fi

FIND_CMD=(find "$SCRIPT_DIR")
for ex in "${EXCLUDES[@]}"; do
  FIND_CMD+=(-path "$SCRIPT_DIR/$ex" -prune -o)
done
FIND_CMD+=(-print)

FILES=()
while IFS= read -r line; do FILES+=("$line"); done < <("${FIND_CMD[@]}" | sed "s|^$SCRIPT_DIR/||")

case "$SORT_METHOD" in
  size) FILES=( $(for f in "${FILES[@]}"; do [ -e "$SCRIPT_DIR/$f" ] && echo "$(stat -f%z "$SCRIPT_DIR/$f" 2>/dev/null) $f"; done | sort -n | cut -d' ' -f2-) ) ;;
  time) FILES=( $(for f in "${FILES[@]}"; do [ -e "$SCRIPT_DIR/$f" ] && echo "$(stat -f%m "$SCRIPT_DIR/$f" 2>/dev/null) $f"; done | sort -n | cut -d' ' -f2-) ) ;;
  *) FILES=( $(printf "%s\n" "${FILES[@]}" | sort) ) ;;
esac

if [ "$DIR_FIRST" = true ]; then
  DIRS=(); REGULAR=()
  for path in "${FILES[@]}"; do
    [ -d "$SCRIPT_DIR/$path" ] && DIRS+=("$path") || REGULAR+=("$path")
  done
  FILES=( "${DIRS[@]}" "${REGULAR[@]}" )
fi

echo "."
for i in "${!FILES[@]}"; do
  path="${FILES[$i]}"
  [ -z "$path" ] && continue

  IFS='/' read -r -a PARTS <<< "$path"
  depth="${#PARTS[@]}"
  [ "$DEPTH_LIMIT" -gt 0 ] && [ "$depth" -gt "$DEPTH_LIMIT" ] && continue

  name="${PARTS[$((depth - 1))]}"
  [ "$SHOW_HIDDEN" = false ] && [[ "$name" == .* ]] && continue

  if [ -n "$ONLY_EXT" ]; then
    ext="${name##*.}"
    match=false
    IFS=',' read -ra EXTLIST <<< "$ONLY_EXT"
    for e in "${EXTLIST[@]}"; do [[ "$ext" == "$e" ]] && match=true; done
    [ "$match" = false ] && continue
  fi

  [ -n "$MATCH_PATTERN" ] && [[ "$path" != *"$MATCH_PATTERN"* ]] && continue

  full="$SCRIPT_DIR/$path"
  is_dir=false
  [ -d "$full" ] && is_dir=true
  [ "$DIRS_ONLY" = true ] && [ "$is_dir" = false ] && continue
  [ "$FILES_ONLY" = true ] && [ "$is_dir" = true ] && continue

  next="${FILES[$((i+1))]:-}"
  next_depth=$(echo "$next" | awk -F'/' '{print NF}')
  branch="├──"
  [ "$next_depth" -le "$depth" ] && branch="└──"

  indent=""
  for ((j=1; j<depth; j++)); do indent+="│  "; done

  icon=""
  ext="${name##*.}"
  [ "$SHOW_ICONS" = true ] && icon=" $([ "$is_dir" = true ] && echo "$FOLDER_ICON" || declare_icon "$ext")"

  size=""
  if [ "$SHOW_SIZES" = true ] && [ -f "$full" ]; then
    sz=$(stat -f%z "$full" 2>/dev/null)
    size=" [$((sz / 1024)) KB]"
    total_bytes=$((total_bytes + sz))
  fi

  perms=""
  [ "$SHOW_PERMS" = true ] && perms="$(stat -f%A "$full" 2>/dev/null) "

  owner=""
  [ "$SHOW_OWNERS" = true ] && owner="$(stat -f'%Su:%Sg' "$full" 2>/dev/null) "

  mtime=""
  [ "$SHOW_MTIME" = true ] && mtime=" [$(date -r "$full" "+%Y-%m-%d %H:%M")]"

  color=""
  if [ "$NO_COLOR" = false ]; then
    ext="${name##*.}"
    case "$ext" in
      ts) color="\033[38;5;39m" ;;
      js) color="\033[38;5;226m" ;;
      py) color="\033[38;5;38m" ;;
      sh) color="\033[38;5;34m" ;;
      md) color="\033[38;5;135m" ;;
      pas) color="\033[38;5;203m" ;;
      asm|s) color="\033[38;5;240m" ;;
      png|jpg|jpeg|gif|webp) color="\033[38;5;214m" ;; # image types
      svg|ico|icns) color="\033[38;5;208m" ;;           # icons
      html|htm) color="\033[38;5;166m" ;;
      css) color="\033[38;5;92m" ;;
      json|yml|yaml|toml) color="\033[38;5;220m" ;;
      pdf) color="\033[38;5;124m" ;;
      txt|log) color="\033[38;5;244m" ;;
      *) color="$RESET" ;;
    esac
  fi

  prefix="${indent}${branch}${icon} "
  display="${perms}${owner}${color}${name}${RESET}${size}${mtime}"

  $is_dir && dir_count=$((dir_count + 1)) || file_count=$((file_count + 1))

  if [ "$MARKDOWN" = true ]; then
    printf "%s- %s%s%s\n" "$indent" "$icon" "$name" "$size"
  else
    echo -e "${prefix}${display}"
  fi
done

if [ "$SUMMARY" = true ]; then
  echo ""
  echo -e "📦 Summary: ${file_count} files, ${dir_count} folders, $((total_bytes / 1024)) KB total"
fi