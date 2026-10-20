#!/bin/bash
# Guardrails must reject bad public release settings before invoking a build.
set -euo pipefail
cd "$(dirname "$0")/.."
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
mkdir "$test_dir/bin"
cat > "$test_dir/bin/swift" <<'STUB'
#!/bin/bash
: > "$PACKAGE_TEST_BUILD_MARKER"
exit 99
STUB
chmod +x "$test_dir/bin/swift"
export PACKAGE_TEST_BUILD_MARKER="$test_dir/build-invoked"
export PATH="$test_dir/bin:$PATH"
unset SIGN_IDENTITY NOTARY_APPLE_ID NOTARY_TEAM_ID NOTARY_PASSWORD REQUIRE_NOTARIZATION

expect_rejection() {
  local expected=$1
  shift
  if "$@" > "$test_dir/output" 2>&1; then
    echo "Expected rejection: $expected" >&2
    exit 1
  fi
  if ! grep -q "$expected" "$test_dir/output" || [[ -e "$PACKAGE_TEST_BUILD_MARKER" ]]; then
    cat "$test_dir/output" >&2
    echo 'Validation did not stop before building.' >&2
    exit 1
  fi
}

expect_rejection 'Version must' bash scripts/package.sh ../invalid
expect_rejection 'Version must' bash scripts/package.sh 1.0.0-beta
expect_rejection 'requires SIGN_IDENTITY' env REQUIRE_NOTARIZATION=1 bash scripts/package.sh 1.0.0
expect_rejection 'Set NOTARY_TEAM_ID' env SIGN_IDENTITY=test NOTARY_APPLE_ID=test@example.com bash scripts/package.sh 1.0.0
expect_rejection 'Set NOTARY_PASSWORD' env SIGN_IDENTITY=test NOTARY_APPLE_ID=test@example.com NOTARY_TEAM_ID=TEAM bash scripts/package.sh 1.0.0
echo 'Packaging guardrails: 5 checks passed.'
