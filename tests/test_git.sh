#!/bin/bash
set -e
#deps: git
#desc: Test git installation

PREFIX="${INSTALL_PREFIX:-${1:-C:/w64devkit}}"
GIT="$PREFIX/bin/git.exe"

"$GIT" --version >/dev/null

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export GIT_CONFIG_NOSYSTEM=1
export HOME="$tmp"

mkdir -p "$tmp/repo"
(
  cd "$tmp/repo"
  "$GIT" init -q
  "$GIT" config user.email tester@example.com
  "$GIT" config user.name tester
  echo "hello git" > hello.txt
  "$GIT" add hello.txt
  "$GIT" commit -q -m "init"
  "$GIT" clone -q . "$tmp/clone"
)
test -f "$tmp/clone/hello.txt"

# The wincred credential helper must be installed and set as the default so
# HTTPS auth works without a console (Windows Credential Manager).
test -x "$PREFIX/bin/git-credential-wincred.exe" || { echo "git-credential-wincred.exe missing"; exit 1; }
test "$("$GIT" config --file "$PREFIX/etc/gitconfig" --get credential.helper)" = "wincred" || { echo "system credential.helper != wincred"; exit 1; }
echo "git OK: $("$GIT" --version)"
