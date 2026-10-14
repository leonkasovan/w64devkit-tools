#!/bin/bash
set -e
#deps: none
#desc: Command-line JSON processor (jq.exe)
#version: 1.7.1
#name: jq

source "$(dirname "$0")/common.sh"
skip_if_installed "jq" "$INSTALL_PREFIX/bin/jq.exe" "jq"

wget https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-1.7.1.tar.gz -O jq-1.7.1.tar.gz
# sanity check: GitHub can return an HTML error page instead of the file
if [ "$(od -An -N2 -tx1 jq-1.7.1.tar.gz | tr -d ' \n')" != "1f8b" ]; then
    echo "error: jq-1.7.1.tar.gz is not a gzip archive (download failed?)"
    exit 1
fi
tar -xf jq-1.7.1.tar.gz
(
  cd jq-1.7.1
  # The app runs scripts with w64devkit's busybox ash, which parses PATH as
  # colon-separated while the app passes a Windows (semicolon) PATH. Point
  # configure at the tools explicitly and skip host-type autodetection.
  export ac_cv_path_SED="$(command -v sed)"
  export ac_cv_path_GREP="$(command -v grep)"
  export ac_cv_path_EGREP="$(command -v grep) -E"
  export ac_cv_path_FGREP="$(command -v grep) -F"
  export ac_cv_prog_AWK="$(command -v awk)"
  export SHELL="$(command -v sh)"
  export LD="$(command -v ld)"
  export AR="$(command -v ar)"
  export AS="$(command -v as)"
  export DLLTOOL="$(command -v dlltool)"
  export NM="$(command -v nm)"
  export OBJDUMP="$(command -v objdump)"
  export RANLIB="$(command -v ranlib)"
  export STRIP="$(command -v strip)"
  # GCC 14+ defaults to C23 where () means "no params", breaking oniguruma's
  # K&R-style function pointers (ANYARGS, st.h). Force C17 to avoid this.
  CFLAGS="-std=gnu17 $CFLAGS"
  ./configure --prefix="$INSTALL_PREFIX" --build=x86_64-w64-mingw32 \
      CFLAGS="-O2 -DNDEBUG $CFLAGS" \
      LDFLAGS="-s" \
      --host=x86_64-w64-mingw32 \
      --disable-docs \
      --with-oniguruma=builtin \
      CC="$INSTALL_PREFIX/bin/gcc" \
      GREP="$(command -v grep)" \
      EGREP="$(command -v grep) -E" \
      FGREP="$(command -v grep) -F" \
      AWK="$(command -v awk)" \
      SED="$(command -v sed)" \
      SHELL="$(command -v sh)" \
      CONFIG_SHELL="$(command -v sh)"
  make -j"$(nproc)"
  make install
)
rm -rf jq-1.7.1 jq-1.7.1.tar.gz
echo "Test: \"$INSTALL_PREFIX\"/bin/jq.exe --version"
