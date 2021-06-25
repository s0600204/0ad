#!/bin/sh
# This script is called by update-workspaces.sh / build-osx-libraries.sh
set -e

# This should match the version in config/milestone.txt
FOLDER="mozjs-78.6.0"
# If same-version changes are needed, increment this.
LIB_VERSION="78.6.0+3"
LIB_NAME="mozjs78-ps"

# Since this script is called by update-workspaces.sh, we want to quickly
# avoid doing any work if SpiderMonkey is already built and up-to-date.
# Running SM's Makefile is a bit slow and noisy, so instead we'll make a
# special file and only rebuild if the build.sh version differs.
if [ -e .already-built ] && [ "$(cat .already-built)" = "${LIB_VERSION}" ]
then
    echo "SpiderMonkey is already up to date."
    exit
fi

echo "Building SpiderMonkey..."
echo

# Use Mozilla make on Windows
if [ "${OS}" = "Windows_NT" ]
then
  MAKE="mozmake"
else
  MAKE=${MAKE:="make"}
fi

INSTALL_DIR=$(pwd)
MAKE_OPTS="${JOBS}"

# Standalone SpiderMonkey can not use jemalloc (see https://bugzilla.mozilla.org/show_bug.cgi?id=1465038)
# Jitspew doesn't compile on VS17 in the zydis disassembler - since we don't use it, deactivate it.
CONF_OPTS="--disable-tests
           --disable-jemalloc
           --disable-js-shell
           --without-intl-api
           --enable-shared-js
           --prefix=${INSTALL_DIR}
           --disable-jitspew"

if [ "${OS}" = "Windows_NT" ]
then
  CONF_OPTS="${CONF_OPTS} --with-visual-studio-version=2017 --target=i686"
else
  CONF_OPTS="${CONF_OPTS}"
fi

if [ "`uname -s`" = "Darwin" ]
then
  # Link to custom-built zlib
  export PKG_CONFIG_PATH="=${ZLIB_DIR}:${PKG_CONFIG_PATH}"
  CONF_OPTS="${CONF_OPTS} --with-system-zlib"
  # Specify target versions and SDK
  if [ "${MIN_OSX_VERSION}" ] && [ "${MIN_OSX_VERSION-_}" ]; then
    CONF_OPTS="${CONF_OPTS} --enable-macos-target=$MIN_OSX_VERSION"
  fi
  if [ "${SYSROOT}" ] && [ "${SYSROOT-_}" ]; then
    CONF_OPTS="${CONF_OPTS} --with-macos-sdk=${SYSROOT}"
  fi
fi

LLVM_OBJDUMP=${LLVM_OBJDUMP:=$(command -v llvm-objdump || command -v objdump)}

# Quick sanity check to print explicit error messages
# (Don't run this on windows as it would likely fail spuriously)
if [ "${OS}" != "Windows_NT" ]
then
  [ ! -z "$(command -v rustc)" ] || (echo "Error: rustc is not available. Install the rust toolchain (rust + cargo) before proceeding." && exit 1)
  [ ! -z "${LLVM_OBJDUMP}" ] || (echo "Error: LLVM objdump is not available. Install it (likely via LLVM-clang) before proceeding." && exit 1)
fi

# If Valgrind looks like it's installed, then set up SM to support it
# (else the JITs will interact poorly with it)
if [ -e /usr/include/valgrind/valgrind.h ]
then
  CONF_OPTS="${CONF_OPTS} --enable-valgrind"
fi

# We need to be able to override CHOST in case it is 32bit userland on 64bit kernel
CONF_OPTS="${CONF_OPTS} \
  ${CBUILD:+--build=${CBUILD}} \
  ${CHOST:+--host=${CHOST}} \
  ${CTARGET:+--target=${CTARGET}}"

echo "SpiderMonkey build options: ${CONF_OPTS}"

# It can occasionally be useful to not rebuild everything, but don't do this by default.
REBUILD=${REBUILD:=true}
if $REBUILD = true;
then
  # Delete the existing directory to avoid conflicts and extract the tarball
  rm -rf "$FOLDER"
  if [ ! -e "${FOLDER}.tar.bz2" ];
  then
    # The tarball is committed to svn, but it's useful to let jenkins download it (when testing upgrade scripts).
    download="$(command -v wget || echo "curl -L -o "${FOLDER}.tar.bz2"")"
    $download "https://github.com/wraitii/spidermonkey-tarballs/releases/download/v78.6.0/${FOLDER}.tar.bz2"
  fi

  echo "Uncompressing archive..."
  tar xjf "${FOLDER}.tar.bz2"

  # Clean up files that may be left over by earlier versions of SpiderMonkey
  if [ "${OS}" = "Windows_NT" ]; then
    rm -rf include-win32-debug
    rm -rf include-win32-release
    rm -rf lib/
  else
    rm -rf include-unix-debug
    rm -rf include-unix-release
    
    # Remove everything except the Windows libs
    rm -rf lib/*.so*
    rm -rf lib/*.a
    rm -rf lib/pkgconfig
  fi
  rm -rf bin
  rm -rf include

  # Apply patches
  cd "$FOLDER"
  . ../patch.sh
  # Prevent complaining that configure is outdated.
  touch ./js/src/configure
else
  cd "$FOLDER"
fi

# Debug version of SM is broken on FreeBSD.
if [ "$(uname -s)" != "FreeBSD" ]; then
  mkdir -p build-debug
  cd build-debug
  # SM configure checks for autoconf, but we don't actually need it.
  # To avoid a dependency, pass something arbitrary (it does need to be an actual program).
  # llvm-objdump is searched for with the complete name, not simply 'objdump', account for that.
  CXXFLAGS="${CXXFLAGS}" ../js/src/configure AUTOCONF="ls" \
    LLVM_OBJDUMP="${LLVM_OBJDUMP}" \
    ${CONF_OPTS} \
    --enable-debug \
    --disable-optimize \
    --enable-gczeal
  ${MAKE} ${MAKE_OPTS} && ${MAKE} install
  cd ..
fi

mkdir -p build-release
cd build-release
CXXFLAGS="${CXXFLAGS}" ../js/src/configure AUTOCONF="ls" \
  LLVM_OBJDUMP="${LLVM_OBJDUMP}" \
  ${CONF_OPTS} \
  --enable-optimize
${MAKE} ${MAKE_OPTS} && ${MAKE} install
cd ..

cd ..

pyrogenesis_dir="../../../binaries/system/"

if [ "${OS}" = "Windows_NT" ]; then
  # Bug #776126
  # SpiderMonkey uses a tweaked zlib when building, and it wrongly copies its own files to include dirs
  # afterwards, so we have to remove them to not have them conflicting with the regular zlib
  pushd include/${LIB_NAME}-debug/
  rm -f mozzconf.h zconf.h zlib.h
  popd
  pushd include/${LIB_NAME}-release/
  rm -f mozzconf.h zconf.h zlib.h
  popd

  # Move headers to where extern_libs5.lua can find them
  # By having the (version-tracked) windows headers in a separate folder, we don't replace them
  # when building on Linux/BSD/OSX, as this might lead to mistakenly committing the replaced headers.
  #mv include/${LIB_NAME}-debug   include-win32-debug
  #mv include/${LIB_NAME}-release include-win32-release

  # Copy DLLs and debug symbols to binaries/system
  #cp -L lib/*.dll ${pyrogenesis_dir}
  #cp -L lib/*.pdb ${pyrogenesis_dir}

  # Windows need some additional libraries for posix emulation.
  cp -L ${FOLDER}/build-release/dist/bin/nspr4.dll lib/
  cp -L ${FOLDER}/build-release/dist/bin/plc4.dll  lib/
  cp -L ${FOLDER}/build-release/dist/bin/plds4.dll lib/

else
  LIB_SUFFIX=.so
  if [ "`uname -s`" = "OpenBSD" ]; then
    LIB_SUFFIX=.so.1.0
  fi

  # Copy the .pc files to somewhere that pkg-config can find them
  if [ $PC_DIR ]; then
    cp -L lib/pkgconfig/*.pc "${PC_DIR}"
  fi

  # Create hard links of shared libraries so as to save space, but still allow bundling to be possible (in theory)
  if [ "`uname -s`" != "Darwin" ]; then
    ln -f lib/*${LIB_SUFFIX} ${pyrogenesis_dir}
  fi

  # Remove a copy of a static library we don't use to save ~650 MiB file space
  rm lib/libjs_static.ajs

fi

# Flag that it's already been built successfully so we can skip it next time
echo "${LIB_VERSION}" > .already-built
