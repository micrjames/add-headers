#!/usr/bin/env bats

load '../helpers/test_helper.bash'

setup() {
	TMPDIR=$(mktemp -d)
	cp "$BATS_TEST_DIRNAME/../../add_headers.sh" "$TMPDIR/"
	cp ../fixtures/* "$TMPDIR/" 2>/dev/null || true
	cd "$TMPDIR"
}

teardown() {
	rm -rf "$TMPDIR"
}

@test "TODO: Header is added to existing file" {
  skip
}

@test "TODO: Original content is preserved" {
  skip
}

@test "TODO: Fails gracefully on missing file" {
  skip
}


@test "TODO: Preserves file permissions" {
  skip
}

@test "TODO: Works with filenames with spaces" {
  skip
}

@test "Sanity: pass" {
  [ 1 -eq 1 ]
}

@test "Meta: fail" {
  [ 1 -eq 0 ]
}

@test "Meta: skip" {
  skip "just testing skip"
}
