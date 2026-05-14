# nix-lefthook-rubocop

[![CI](https://github.com/pr0d1r2/nix-lefthook-rubocop/actions/workflows/ci.yml/badge.svg)](https://github.com/pr0d1r2/nix-lefthook-rubocop/actions/workflows/ci.yml)

> This code is LLM-generated and validated through an automated integration process using [lefthook](https://github.com/evilmartians/lefthook) git hooks, [bats](https://github.com/bats-core/bats-core) unit tests, and GitHub Actions CI.

Lefthook-compatible [RuboCop](https://github.com/rubocop/rubocop) hook for pre-commit and pre-push.

Runs `bundle exec rubocop` on staged/pushed Ruby files with `--fail-fast --force-exclusion`.

## Usage

Add to your `lefthook.yml`:

```yaml
remotes:
  - git_url: https://github.com/pr0d1r2/nix-lefthook-rubocop
    ref: main
    configs:
      - lefthook-remote.yml
```

Requires `bundle` and `rubocop` gem in your project's Gemfile.

## Development

```bash
nix develop
bats --recursive tests/unit/
```

## License

MIT
