# Makefile for w64devkit Tools: Library Installer
# Generated from CMakeLists.txt — 2025-06-16
#
# Targets:
#   all / w64devkit-tools.exe     — Build the application
#   clean                         — Remove build artifacts
#
# Overridable variables:
#   CXX        — C++ compiler (default: g++)
#   CC         — C compiler   (default: gcc)
#   AR         — Archiver     (default: ar)
#   WINDRES    — Resource compiler (default: windres)
#   CXXFLAGS   — Extra C++ flags (default: -std=c++17 -static -static-libgcc -static-libstdc++)
#   CFLAGS     — Extra C flags   (default: -std=c17 -static -static-libgcc)
#   config     — Set to "Debug" for debug build (-g, -DDEBUG, no strip)

CXX       ?= g++
CC        ?= gcc
AR        ?= ar
WINDRES   ?= windres

ifeq ($(config),Debug)
CXXFLAGS  := -std=c++17 -static -static-libgcc -static-libstdc++ -g -DDEBUG
CFLAGS    := -std=c17 -static -static-libgcc -g -DDEBUG
LDFLAGS   := -mwindows
else
CXXFLAGS  ?= -std=c++17 -static -static-libgcc -static-libstdc++
CFLAGS    ?= -std=c17 -static -static-libgcc
LDFLAGS   := -mwindows -s
endif

# ---------------------------------------------------------------------------
# Directories
# ---------------------------------------------------------------------------
SRC_DIR    := .
LIBUI_DIR  := $(SRC_DIR)/libui-ng
RES_DIR    := $(SRC_DIR)/res
BUILD_DIR  := build

# ---------------------------------------------------------------------------
# libui-ng source files (from CMakeLists.txt)
# ---------------------------------------------------------------------------
LIBUI_COMMON_C   := $(wildcard $(LIBUI_DIR)/common/*.c)
LIBUI_COMMON_CPP := $(wildcard $(LIBUI_DIR)/common/*.cpp)
LIBUI_WIN_CPP    := $(wildcard $(LIBUI_DIR)/windows/*.cpp)

LIBUI_SRCS := $(LIBUI_COMMON_C) $(LIBUI_COMMON_CPP) $(LIBUI_WIN_CPP)

# Object files — keep per-directory to avoid collisions (e.g. common/debug.c vs windows/debug.cpp)
LIBUI_COMMON_C_OBJ   := $(patsubst $(LIBUI_DIR)/common/%.c,$(BUILD_DIR)/common/%.o,$(LIBUI_COMMON_C))
LIBUI_COMMON_CPP_OBJ := $(patsubst $(LIBUI_DIR)/common/%.cpp,$(BUILD_DIR)/common/%.o,$(LIBUI_COMMON_CPP))
LIBUI_WIN_OBJ        := $(patsubst $(LIBUI_DIR)/windows/%.cpp,$(BUILD_DIR)/windows/%.o,$(LIBUI_WIN_CPP))

LIBUI_OBJS := $(LIBUI_COMMON_C_OBJ) $(LIBUI_COMMON_CPP_OBJ) $(LIBUI_WIN_OBJ)

# ---------------------------------------------------------------------------
# libui compile flags (matches CMakeLists.txt)
# ---------------------------------------------------------------------------
LIBUI_CXXFLAGS := -I$(LIBUI_DIR) \
                  -Dlibui_EXPORTS -D_UI_STATIC \
                  -Wno-unused-parameter -Wno-switch -Wno-deprecated-declarations

LIBUI_CFLAGS := -I$(LIBUI_DIR) \
                -Dlibui_EXPORTS -D_UI_STATIC \
                -Wno-unused-parameter -Wno-switch -Wno-deprecated-declarations

# ---------------------------------------------------------------------------
# Targets
# ---------------------------------------------------------------------------
.PHONY: all clean

all: w64devkit-tools.exe

# -- Final executable --
w64devkit-tools.exe: $(BUILD_DIR)/main.o $(BUILD_DIR)/libui.a $(BUILD_DIR)/resources.o | $(BUILD_DIR)
	$(CXX) -o $@ $(BUILD_DIR)/main.o $(BUILD_DIR)/libui.a $(BUILD_DIR)/resources.o \
		$(CXXFLAGS) $(LDFLAGS) \
		-luser32 -lkernel32 -lgdi32 -lcomctl32 -luxtheme -lmsimg32 \
		-lwinmm -lcomdlg32 -ld2d1 -ldwrite -lole32 -loleaut32 -loleacc \
		-lusp10 -luuid -lgdiplus -lwindowscodecs

# -- Static library for libui-ng --
$(BUILD_DIR)/libui.a: $(LIBUI_OBJS) | $(BUILD_DIR)
	$(AR) rcs $@ $^

# -- main.cpp --
$(BUILD_DIR)/main.o: main.cpp | $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) -I$(LIBUI_DIR) -D_UI_STATIC -c $< -o $@

# -- libui .c files (common) --
$(BUILD_DIR)/common/%.o: $(LIBUI_DIR)/common/%.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) $(LIBUI_CFLAGS) -c $< -o $@

# -- libui .cpp files (common) --
$(BUILD_DIR)/common/%.o: $(LIBUI_DIR)/common/%.cpp | $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) $(LIBUI_CXXFLAGS) -c $< -o $@

# -- libui .cpp files (windows) --
$(BUILD_DIR)/windows/%.o: $(LIBUI_DIR)/windows/%.cpp | $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) $(LIBUI_CXXFLAGS) -c $< -o $@

# -- Resources --
# res/resources.rc includes "winapi.hpp" and "resources.hpp" from libui-ng/windows/
# and references "libui.manifest" from res/
$(BUILD_DIR)/resources.o: $(RES_DIR)/resources.rc $(RES_DIR)/libui.manifest \
                          $(LIBUI_DIR)/windows/winapi.hpp $(LIBUI_DIR)/windows/resources.hpp | $(BUILD_DIR)
	$(WINDRES) -i $(RES_DIR)/resources.rc -o $@ \
		-I$(RES_DIR) -I$(LIBUI_DIR)/windows

# -- Create build directory structure --
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)/common $(BUILD_DIR)/windows

# -- Clean --
clean:
	rm -rf $(BUILD_DIR)
