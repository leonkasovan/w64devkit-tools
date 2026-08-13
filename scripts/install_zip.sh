#!/bin/bash
set -e
#deps: none
#desc: Info-ZIP zip archiver (zip.exe)
#version: 3.0
#name: zip

source "$(dirname "$0")/common.sh"
skip_if_installed "zip" "$INSTALL_PREFIX/bin/zip.exe" "zip"

wget "https://sourceforge.net/projects/infozip/files/Zip%203.x%20%28latest%29/3.0/zip30.tar.gz/download" -O zip30.tar.gz
# sanity check: SourceForge can return an HTML error page instead of the file
if [ "$(od -An -N2 -tx1 zip30.tar.gz | tr -d ' \n')" != "1f8b" ]; then
    echo "error: zip30.tar.gz is not a gzip archive (download failed?)"
    exit 1
fi
tar -xf zip30.tar.gz
(
  cd zip30
  # zip.h defines a macro named CR, which collides with identifiers used
  # in MinGW-w64's windows.h headers; rename it to ZIPCR.
  sed -i 's/^#define CR /#define ZIPCR /' zip.h
  sed -i -e 's/= CR;/= ZIPCR;/' -e 's/= CR,/= ZIPCR,/' -e 's/== CR /== ZIPCR /' zipup.c
  # The win32 makefile builds 32-bit-only i386 assembly objects and
  # win32/osdep.h auto-enables them. Drop them and use the portable C
  # implementations instead (required for x86_64 MinGW-w64).
  sed -i 's/^CRCAUO = crci386_.o/CRCAUO =/' win32/makefile.gcc
  sed -i 's/^OBJA  = match.o $(CRCA_O)/OBJA  =/' win32/makefile.gcc
  sed -i 's/^LOC = .*/LOC = -DNO_ASM $(LOCAL_ZIP)/' win32/makefile.gcc
  make -f win32/makefile.gcc
)
mkdir -p "$INSTALL_PREFIX"/bin
cp -f zip30/zip.exe zip30/zipnote.exe zip30/zipsplit.exe zip30/zipcloak.exe "$INSTALL_PREFIX"/bin/
rm -r zip30 zip30.tar.gz
echo "Test: \"$INSTALL_PREFIX\"/bin/zip.exe -h"
