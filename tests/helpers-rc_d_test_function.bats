#!/usr/bin/env bats

setup() {
  load test_helper
  setup_rc_d_test
  . rc_d_test.lib
  desc="rc d test function is a test function in rc.d.test.lib"
}

@test "rc_d_test_function" {
  assert rc_d_test_function
  run rc_d_test_function
  assert_output - <<STDIN
DEBUG: ${DEBUG:-}
DRYRUN: ${DRYRUN:-}
QUIET: ${QUIET:-}
VERBOSE: ${VERBOSE:-}
WARNING: ${WARNING:-}
args: ${args:-}
STDIN
}

@test "rc_d_test_function --debug --dryrun --quiet --verbose --warning" {
  run rc_d_test_function --debug --dryrun --quiet --verbose --warning
  [ "$status" -eq 0 ]
  assert_output - <<STDIN
DEBUG: 1
DRYRUN: 1
QUIET: 1
VERBOSE: 1
WARNING: 1
args: ${args:-}
STDIN
}

@test "rc_d_test_function --debug --dryrun --other-option --quiet --verbose --warning opt" {
  run rc_d_test_function --debug --dryrun --quiet --other-option --verbose --warning opt
  [ "$status" -eq 0 ]
  assert_output - <<STDIN
DEBUG: 1
DRYRUN: 1
QUIET: 1
VERBOSE: 1
WARNING: 1
args: --other-option opt
--other-option
opt
STDIN
}

@test "rc_d_test_function --desc" {
  run rc_d_test_function --desc
  [ "$status" -eq 0 ]
  assert_output - <<STDIN
${desc}
STDIN
}

@test "rc_d_test_function --verbose --desc opt" {
  run rc_d_test_function --desc
  [ "$status" -eq 0 ]
  assert_output - <<STDIN
${desc}
STDIN
}

@test "rc_d_test_function --help: Error" {
  run rc_d_test_function --help
  assert_failure
}

@test "rc_d_test_function --version: Error" {
  run rc_d_test_function --help
  assert_failure
}

@test "rc_d_test_function --man-repo: Error" {
  run rc_d_test_function --help
  assert_failure
}