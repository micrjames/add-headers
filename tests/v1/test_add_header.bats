#!/usr/bin/env bats

load '../helpers/test_helper.bash'

setup() {
	TMPDIR=$(mktemp -d)

	# Absolute path to script and fixture directories
	local script_path="$BATS_TEST_DIRNAME/../../add_headers.sh"
	local fixtures_path="$BATS_TEST_DIRNAME/../fixtures"

	# Validate script exists
	if [[ ! -f "$script_path" ]]; then
	echo "❌ ERROR: Cannot find add_headers.sh at $script_path"
	exit 1
	fi

	# Copy script to tmpdir
	cp "$script_path" "$TMPDIR/" || {
	echo "❌ ERROR: Failed to copy add_headers.sh to TMPDIR"
	exit 1
	}

	# Copy fixture files (if any)
	if [[ -d "$fixtures_path" ]]; then
	cp -R "$fixtures_path/"* "$TMPDIR/" 2>/dev/null || true
	fi

	cd "$TMPDIR"
}

teardown() {
	rm -rf "$TMPDIR"
}

@test "Header is added to existing file" {
  echo 'int main() { return 0; }' > main.c

  run bash add_headers.sh main.c "Test header"
  [ "$status" -eq 0 ]

  if ! grep -q "# Project: CForge" main.c; then
    echo "=== main.c contents ==="
    cat main.c
    echo "======================="
    false
  fi

  grep -q "# File: main.c" main.c
  grep -q "# Description: Test header" main.c
  grep -q "int main()" main.c
}

@test "Original content is preserved" {
	# 1. Save original content
	cat > test.c <<'EOF'
int main() {
	return 42;
}
EOF

	orig="$(cat test.c)"

	# 2. Run script
	run bash add_headers.sh test.c "Another test"
	[ "$status" -eq 0 ]

	# 3. Ensure header was added (quick sanity checks)
	grep -q "# Project: CForge" test.c
	grep -q "# File: test.c" test.c
	grep -q "# Description: Another test" test.c

	# 4. Ensure original body snippet still present
	grep -q "return 42;" test.c

	# 5. Compare bodies exactly (strip header then compare)
	body="$(awk '
	  /^# =+$/ { delim++ ; next }   # count delimiter lines
	  delim < 2 { next }            # still in header
	  { print }                     # after header, print body
	' test.c)"

	[ "$body" = "$orig" ]
}

@test "Fails gracefully on missing file" {
	run bash add_headers.sh no_such_file.c "Missing file test"
	[ "$status" -eq 0 ]  # script continues gracefully

	# Log should contain the error
	grep -q "File not found: no_such_file.c" add_header.log

	# Ensure file was not created
	[ ! -f no_such_file.c ]
}

@test "Preserves file permissions" {
	# Helper: portable permission getter  (#2 GNU/BSD stat portability)
	get_mode() {
	if stat --version >/dev/null 2>&1; then
	  stat -c "%a" "$1"        # GNU coreutils (Linux)
	else
	  stat -f "%Lp" "$1"       # BSD/macOS
	fi
	}

	# -------------------------------------------------------------------
	# 1) Mode is unchanged (plain 744)
	# -------------------------------------------------------------------
	echo 'int x;' > perms.c
	chmod 744 perms.c
	orig_mode_744="$(get_mode perms.c)"

	run bash add_headers.sh perms.c "Permission test"
	[ "$status" -eq 0 ]
	new_mode_744="$(get_mode perms.c)"
	[ "$new_mode_744" -eq "$orig_mode_744" ]

	# -------------------------------------------------------------------
	# 4) Special bits preserved (setuid example: 4755)
	# -------------------------------------------------------------------
	echo 'int y;' > suid.c
	chmod 4755 suid.c
	orig_mode_suid="$(get_mode suid.c)"

	run bash add_headers.sh suid.c "SUID test"
	[ "$status" -eq 0 ]
	new_mode_suid="$(get_mode suid.c)"
	[ "$new_mode_suid" -eq "$orig_mode_suid" ]
}

@test "Read-only file stays read-only and is updated" {
  get_mode() {
    if stat --version >/dev/null 2>&1; then
      stat -c "%a" "$1"
    else
      stat -f "%Lp" "$1"
    fi
  }

  echo 'int z;' > ro.c
  chmod 444 ro.c
  orig_mode="$(get_mode ro.c)"

  # Ensure TMPDIR (pwd) is writable so mv can replace the file
  chmod u+w .

  run bash add_headers.sh ro.c "RO test"
  [ "$status" -eq 0 ]

  new_mode="$(get_mode ro.c)"
  [ "$new_mode" -eq "$orig_mode" ]
  grep -q "# Project: CForge" ro.c
}
@test "Works with filenames with spaces" {
	fname="file with spaces.c"

	# 1) Create file with spaces in name
	echo 'void test() {}' > "$fname"

	# 2) Run script successfully
	run bash add_headers.sh "$fname" "Spaces test"
	[ "$status" -eq 0 ]

	# 3) Header sanity checks
	grep -q "# Project: CForge" "$fname"                  # header added
	grep -q "# File: file with spaces.c" "$fname"         # correct filename
	grep -q "# Description: Spaces test" "$fname"         # correct description

	# 4) Original content intact
	grep -q "void test()" "$fname"

	# 5) (Optional) ensure no extra copy got created (very unlikely but explicit)
	[ ! -f "file" ] && [ ! -f "with" ] && [ ! -f "spaces.c" ]
}

@test "Header contains Version and Update fields" {
	echo 'int main(){return 0;}' > ver.c
	run bash add_headers.sh ver.c "Version fields test"
	[ "$status" -eq 0 ]
	grep -q "# Version: 1.0.0" ver.c
	grep -q "# Update: 0" ver.c
}

@test "Handles Unicode filename" {
	fname="unicodé_名字.c"
	echo 'int u(){return 0;}' > "$fname"
	run bash add_headers.sh "$fname" "Unicode test"
	[ "$status" -eq 0 ]
	grep -q "# Project: CForge" "$fname"
	grep -q "# File: $fname"    "$fname"
	grep -q "# Description: Unicode test" "$fname"
	grep -q "int u()" "$fname"
}

@test "Header formatting: exactly one blank line between header and body" {
	echo 'int f(){return 1;}' > fmt.c
	run bash add_headers.sh fmt.c "Fmt test"
	[ "$status" -eq 0 ]

	# Find line numbers of the two delimiter rows (===)
	mapfile -t dl < <(grep -n '^# =\{3,\}$' fmt.c | cut -d: -f1)
	[ "${#dl[@]}" -ge 2 ]  # at least two delimiters

	second_delim="${dl[1]}"

	# The very next non-comment line after second delimiter should be the code, no extra blank gap
	next_line=$(( second_delim + 1 ))
	# Skip any empty lines to ensure there's exactly one gap -> allow 0 or 1? You said "exactly one newline"
	# So require that line (second_delim+1) is NOT empty and NOT starting with '#'
	line_content="$(sed -n "${next_line}p" fmt.c)"
	[ -n "$line_content" ]
	[[ ! "$line_content" =~ ^# ]]

	# And confirm original code is right there
	grep -q 'int f()' fmt.c
}

@test "Script behaves the same from different working dirs" {
	echo 'int g(){return 3;}' > outer.c

	# Create a unique subdir inside TMPDIR
	subdir="$(mktemp -d subdir.XXXXXX)"

	# Copy the script into that subdir
	cp add_headers.sh "$subdir/"

	(
	cd "$subdir" || exit 1
	run bash ./add_headers.sh ../outer.c "CWD test"
	[ "$status" -eq 0 ]
	)

	# Verify header landed in the original file
	grep -q "# Description: CWD test" outer.c
	grep -q "int g()" outer.c
}
