#!/bin/bash
set -e
#deps: astyle
#desc: Test AStyle installation

PREFIX="${INSTALL_PREFIX:-${1:-C:/w64devkit}}"
ASTYLE="$PREFIX/bin/astyle.exe"

"$ASTYLE" --version >/dev/null

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cat > "$tmp/ugly.cpp" <<'EOF'
int main(){
int x=1;if(x==1){
return 0;}
return 1;}
EOF

"$ASTYLE" --style=java "$tmp/ugly.cpp"
# astyle modifies in-place; check the file was reformatted
if grep -q 'int main(){' "$tmp/ugly.cpp"; then
    echo "error: astyle did not reformat the file"
    exit 1
fi
echo "astyle OK: formatted ugly.cpp"
