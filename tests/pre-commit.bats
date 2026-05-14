#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"

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
    cmd=$(awk '/^pre-commit:/,/run:/' "$REPO_ROOT/lefthook-remote.yml" \
        | grep 'run:' | head -1 | sed 's/.*run: //')
    echo "$cmd"
}

@test "pre-commit run command calls bundle exec rubocop" {
    cmd=$(run_cmd)
    echo "$cmd" | grep -q "bundle exec rubocop"
}

@test "pre-commit run command includes --fail-fast" {
    cmd=$(run_cmd)
    echo "$cmd" | grep -q "\-\-fail-fast"
}

@test "pre-commit run command includes --force-exclusion" {
    cmd=$(run_cmd)
    echo "$cmd" | grep -q "\-\-force-exclusion"
}

@test "pre-commit run command includes {staged_files}" {
    cmd=$(run_cmd)
    echo "$cmd" | grep -q "{staged_files}"
}

@test "pre-commit glob targets ruby files" {
    glob=$(awk '/^pre-commit:/,/glob:/' "$REPO_ROOT/lefthook-remote.yml" \
        | grep 'glob:' | head -1 | sed 's/.*glob: //' | tr -d '"')
    [ "$glob" = "**/*.rb" ]
}

@test "pre-commit has timeout" {
    timeout=$(awk '/^pre-commit:/,/timeout:/' "$REPO_ROOT/lefthook-remote.yml" \
        | grep 'timeout:' | head -1 | sed 's/.*timeout: //')
    [ -n "$timeout" ]
}

@test "pre-commit passes files to rubocop via bundle exec" {
    echo "class Foo; end" > "$WORK/app.rb"

    cmd=$(run_cmd)
    cmd="${cmd//\{staged_files\}/app.rb}"

    run bash -c "cd '$WORK' && $cmd"
    assert_success

    run cat "$STUB_LOG"
    assert_output --partial "bundle exec"
    assert_output --partial "app.rb"
}

@test "pre-commit propagates rubocop failure" {
    export STUB_EXIT=1
    echo "class Foo; end" > "$WORK/app.rb"

    cmd=$(run_cmd)
    cmd="${cmd//\{staged_files\}/app.rb}"

    run bash -c "cd '$WORK' && $cmd"
    assert_failure
}

@test "pre-commit passes multiple files" {
    echo "class Foo; end" > "$WORK/app.rb"
    echo "class Bar; end" > "$WORK/bar.rb"

    cmd=$(run_cmd)
    cmd="${cmd//\{staged_files\}/app.rb bar.rb}"

    run bash -c "cd '$WORK' && $cmd"
    assert_success

    run cat "$STUB_LOG"
    assert_output --partial "app.rb"
    assert_output --partial "bar.rb"
}
