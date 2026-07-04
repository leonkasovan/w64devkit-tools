#!/bin/bash
# Test all installed libraries by compiling and running a minimal program.
# Uses pkg-config when available, falls back to known library flags.

set -e
INSTALL_PREFIX="${1:-C:/w64devkit}"
CC="${CC:-$INSTALL_PREFIX/bin/g++}"
FAILED=0
PASSED=0

export PATH="$INSTALL_PREFIX/bin:$PATH"
export PKG_CONFIG_PATH="$INSTALL_PREFIX/lib/pkgconfig"
PKGCONFIG="$INSTALL_PREFIX/bin/pkg-config"

run_test() {
    local name="$1" src="$2"
    shift 2
    local cflags="" libs=""
    if $PKGCONFIG --exists "$1" 2>/dev/null; then
        cflags=$($PKGCONFIG --cflags "$1")
        libs=$($PKGCONFIG --libs "$1")
        shift
    fi
    # append any extra libs passed as remaining args
    local extra=""
    while [ $# -gt 0 ]; do extra="$extra $1"; shift; done

    echo -n "Testing $name... "
    if $CC -std=c++17 -static tests/test_${src}.cpp -o /tmp/test_${src}.exe \
        -I"$INSTALL_PREFIX/include" -L"$INSTALL_PREFIX/lib" \
        $cflags $libs $extra 2>/dev/null; then
        if /tmp/test_${src}.exe 2>/dev/null || [ $? -eq 0 ]; then
            echo "PASS"
            PASSED=$((PASSED + 1))
        else
            echo "FAIL (runtime)"
            FAILED=$((FAILED + 1))
        fi
        rm -f /tmp/test_${src}.exe
    else
        echo "FAIL (compile)"
        $CC -std=c++17 -static tests/test_${src}.cpp -o /tmp/test_${src}.exe \
            -I"$INSTALL_PREFIX/include" -L"$INSTALL_PREFIX/lib" \
            $cflags $libs $extra 2>&1 | head -3
        FAILED=$((FAILED + 1))
    fi
}

run_test "zlib"      "zlib"      "zlib"           -lzs
run_test "bz2"       "bz2"       "bzip2"          ""
run_test "brotli"    "brotli"    "libbrotlidec"   ""
run_test "curl"      "curl"      "libcurl"        ""
run_test "flac"      "flac"      "flac"           -logg
run_test "fmt"       "fmt"       "fmt"            ""
run_test "freetype"  "freetype"  "freetype2"      ""
run_test "glfw"      "glfw"      "glfw3"          ""
run_test "gme"       "gme"       "libgme"         ""
run_test "glew"      "glew"      "glew"           ""
run_test "harfbuzz"  "harfbuzz"  "harfbuzz"       -lfreetype
run_test "jpeg"      "jpeg"      "libjpeg"        ""
run_test "json"      "json"      "nlohmann_json"  ""
run_test "lzma"      "lzma"      "liblzma"        ""
run_test "minizip"   "minizip"   "minizip"        -lz
run_test "libuv"     "libuv"     "libuv"          ""
run_test "mpg123"    "mpg123"    "libmpg123"      ""
run_test "ogg"       "ogg"       "ogg"            ""
run_test "opus"      "opus"      "opus"           ""
run_test "opusfile"  "opusfile"  "opusfile"       -lopus
run_test "pcre2"     "pcre2"     "libpcre2-8"     ""
run_test "physfs"    "physfs"    "physfs"         ""
run_test "png"       "png"       "libpng"         -lz
run_test "raylib6"   "raylib6"   "raylib"         ""
run_test "sdl2"      "sdl2"      "sdl2"           ""
run_test "sdl3"      "sdl3"      "sdl3"           ""
run_test "sqlite3"   "sqlite3"   "sqlite3"        ""
run_test "wavpack"   "wavpack"   "wavpack"        ""
run_test "webp"      "webp"      "libwebp"        ""
run_test "xml"       "xml"       "expat"          ""
run_test "xmp"       "xmp"       "libxmp"         ""
run_test "zstd"      "zstd"      "libzstd"        ""
run_test "sdl2image" "sdl2image" "SDL2_image"     -lSDL2 -lpng -ljpeg -lwebp
run_test "sdl2mixer" "sdl2mixer" "SDL2_mixer"     -lSDL2
run_test "sdl2ttf"   "sdl2ttf"   "SDL2_ttf"       -lSDL2 -lfreetype

echo ""
echo "=== Results: $PASSED passed, $FAILED failed ==="
exit $FAILED
