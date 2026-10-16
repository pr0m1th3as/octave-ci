#!/bin/bash
# Builds Open CASCADE for GNU Octave for Windows with the compiler, CMake and
# make that come with that Octave, and packs its DLLs, import libraries,
# headers and licence as occt-VERSION-octave-OCTAVE-w64.tar.gz, with its
# .sha256, in OUT.  Runs in Octave's own MSYS shell, whose /mingw64 is
# Octave's folder of that name:
#
#   OCTAVE_ROOT\usr\bin\bash.exe occt/build-windows.sh VERSION OCTAVE OUT [SRC]
#
# SRC is the source archive of the Open CASCADE release, downloaded when not
# given.  The DLLs need Octave's own C++ runtime and FreeType, so a build
# serves the Octave release it was made with.

set -euo pipefail
version="$1"
octave="$2"
out="$(cygpath -u "$3")"
src="${4:+$(cygpath -u "$4")}"
export PATH=/mingw64/bin:/usr/bin:$PATH
m="$(cygpath -m /mingw64)"

# A short folder, since some of Open CASCADE's object paths are long; WORK
# names another
work="$(cygpath -u "${WORK:-C:/occt-build}")"
rm -rf "$work"
mkdir -p "$work" "$out"
cd "$work"
if [ -z "$src" ]; then
  src="$work/src.tar.gz"
  curl -fsSL --retry 3 --retry-all-errors -o "$src" \
    "https://github.com/Open-Cascade-SAS/OCCT/archive/refs/tags/V${version//./_}.tar.gz"
fi
mkdir src
tar -xzf "$src" -C src --strip-components 1

# The libraries the packages link and the viewer needs: no Draw, no samples,
# none of the optional third-party products but FreeType, which is Octave's
cmake -G "MSYS Makefiles" -S src -B build \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$(cygpath -m "$work/stage")" \
  -DINSTALL_DIR_LAYOUT=Unix \
  -DBUILD_LIBRARY_TYPE=Shared \
  -DBUILD_MODULE_Draw=OFF \
  -DUSE_TCL=OFF -DUSE_TK=OFF \
  -DUSE_FREETYPE=ON -DUSE_OPENGL=ON \
  -D3RDPARTY_FREETYPE_DIR="$m" \
  -D3RDPARTY_FREETYPE_INCLUDE_DIR_ft2build="$m/include/freetype2" \
  -D3RDPARTY_FREETYPE_INCLUDE_DIR_freetype2="$m/include/freetype2" \
  -D3RDPARTY_FREETYPE_LIBRARY="$m/lib/libfreetype.dll.a" \
  -D3RDPARTY_FREETYPE_LIBRARY_DIR="$m/lib" \
  -D3RDPARTY_FREETYPE_DLL="$m/bin/libfreetype-6.dll" \
  -D3RDPARTY_FREETYPE_DLL_DIR="$m/bin" \
  -DUSE_FREEIMAGE=OFF -DUSE_FFMPEG=OFF -DUSE_TBB=OFF \
  -DUSE_RAPIDJSON=OFF -DUSE_DRACO=OFF -DUSE_VTK=OFF -DUSE_D3D=OFF \
  -DBUILD_DOC_Overview=OFF
cmake --build build --parallel "$(nproc)"
cmake --install build --strip > /dev/null
grep "define OCC_VERSION_COMPLETE" stage/include/opencascade/Standard_Version.hxx

name="occt-$version-octave-$octave-w64"
cd stage
# The licence and its exception, which installing puts there
tar -czf "$out/$name.tar.gz" bin/*.dll lib/*.dll.a include/opencascade \
  share/doc/opencascade
cd "$out"
sha256sum "$name.tar.gz" > "$name.tar.gz.sha256"
ls -l "$name.tar.gz"
cat "$name.tar.gz.sha256"
