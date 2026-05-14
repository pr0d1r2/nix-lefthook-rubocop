#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"

    export PATH="$BATS_TEST_DIRNAME/stubs:$PATH"
    export STUB_LOG="$BATS_TEST_TMPDIR/stub.log"

    WORK="$BATS_TEST_TMPDIR/repo"
    mkdir -p "$WORK"
    unset GIT_DIR GIT_INDEX_FILE GIT_WORK_TREE 2>/dev/null || true
    git -C "$WORK" init -q
    git -C "$WORK" config user.email "test@test"
    git -C "$WORK" config user.name "Test"
}

run_cmd() {
    local cmd
    cmd=$(awk '/^pre-push:/,/run:/' "$REPO_ROOT/lefthook-remote.yml" \
        | grep 'run:' | head -1 | sed 's/.*run: //')
    echo "$cmd"
}

@test "pre-push run command calls bundle exec rubocop" {
    cmd=$(run_cmd)
    echo "$cmd" | grep -q "bundle exec rubocop"
}

@test "pre-push run command includes --fail-fast" {
    cmd=$(run_cmd)
    echo "$cmd" | grep -q "\-\-fail-fast"
}

@test "pre-push has timeout" {
    timeout=$(awk '/^pre-push:/,/timeout:/' "$REPO_ROOT/lefthook-remote.yml" \
        | grep 'timeout:' | head -1 | sed 's/.*timeout: //')
    [ -n "$timeout" ]
}

@test "pre-push executes rubocop via bundle" {
    cmd=$(run_cmd)

    run bash -c "cd '$WORK' && $cmd"
    assert_success

    run cat "$STUB_LOG"
    assert_output --partial "bundle exec"
    assert_output --partial "--fail-fast"
}

@test "pre-push propagates rubocop failure" {
    export STUB_EXIT=1

    cmd=$(run_cmd)

    run bash -c "cd '$WORK' && $cmd"
    assert_failure
}
