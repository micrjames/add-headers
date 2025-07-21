#!/usr/bin/env bash
# add_headers.sh – prepend a standard header to any file you specify
# Usage: chmod +x add_headers.sh && ./add_headers.sh
# ------------------------------------------------------------------

version="1.0.0"
update="0"
project="CForge"

log_file="./add_header.log"
: > "$log_file"

###############################################################################
# add_header <file> <description>
#   • Creates three temps (header‑only, body‑only, merged)
#   • Merges header + original content, then atomically replaces <file>
###############################################################################
add_header() {
    local file="$1"
    local desc="$2"
    local filename="$(basename "$file")"

    header="# ==========================================
# Project: $project
# File: $filename
# Version: $version
# Update: $update
# Description: $desc
# =========================================="

    # --- create temp files in the same directory as the target ---------------
    local dir="$(dirname "$file")"
    local tmp_header tmp_body tmp_merge
    tmp_header="$(mktemp "${dir}/hdr.XXXXXX")"
    tmp_body="$(mktemp   "${dir}/bod.XXXXXX")"
    tmp_merge="$(mktemp  "${dir}/mrg.XXXXXX")"

    # --- populate temps -------------------------------------------------------
    printf "%s\n" "$header" >"$tmp_header"     # header only
    cat -- "$file"          >"$tmp_body"       # body only
    cat -- "$tmp_header" "$tmp_body" >"$tmp_merge"  # merged

    # --- preserve permissions, replace atomically, clean up -------------------
	# Preserve original mode cross‑platform
	if chmod --reference="$file" "$tmp_merge" 2>/dev/null; then
		:                               # GNU coreutils path succeeded
	else
		perms=$(stat -f "%Lp" "$file")  # BSD/macOS: fetch octal permissions
		chmod "$perms" "$tmp_merge"
	fi
	
    mv -- "$tmp_merge" "$file"
    rm -f -- "$tmp_header" "$tmp_body"

    echo "Header added to $file"
}

###############################################################################
# Example invocations – adjust paths as needed
###############################################################################

files=(
	"create_c_project.sh|Script to scaffold a C project structure"
	"makefile_template/Makefile|Generic build system for multi‑file C projects"
	"makefile_template/makefile_configs/defnfile|Compiler and linker configuration for CForge projects"
	"makefile_template/makefile_configs/outfile|Defines the output binary name"
	"base_ncurses.c|Optional ncurses helper module (source)"
	"base_ncurses.h|Header for optional ncurses helper module"
)

for file in "${files[@]}"; do
	name="${file%%|*}"
	desc="${file#*|}"
	#echo "$name $desc"

	if [[ ! -f "$name" ]]; then
		echo "❌ File not found: $file" | tee -a "$log_file"
		continue
	fi

	add_header "$name" "$desc"
done
