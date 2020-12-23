#!/bin/bash

set -ex
export TRAVIS_BUILD_DIR=$(pwd)
export TRAVIS_BRANCH=$DRONE_BRANCH
export TRAVIS_OS_NAME=${DRONE_JOB_OS_NAME:-linux}
export VCS_COMMIT_ID=$DRONE_COMMIT
export GIT_COMMIT=$DRONE_COMMIT
export DRONE_CURRENT_BUILD_DIR=$(pwd)
export PATH=~/.local/bin:/usr/local/bin:$PATH

echo '==================================> BEFORE_INSTALL'

. .drone/before-install.sh

echo '==================================> INSTALL'

BOOST_BRANCH=develop && [ "$TRAVIS_BRANCH" == "master" ] && BOOST_BRANCH=master || true
cd ..
git clone -b $BOOST_BRANCH https://github.com/boostorg/boost.git boost-root
cd boost-root
git submodule update --init tools/boostdep
git submodule update --init tools/cmake
cp -r $TRAVIS_BUILD_DIR/* libs/timer
python tools/boostdep/depinst/depinst.py timer
./bootstrap.sh
./b2 headers

echo '==================================> BEFORE_SCRIPT'

. $DRONE_CURRENT_BUILD_DIR/.drone/before-script.sh

echo '==================================> SCRIPT'

echo "using $TOOLSET : : $TRAVIS_COMPILER ;" > ~/user-config.jam
./b2 -j3 -l120 --verbose-test libs/timer/test toolset=$TOOLSET cxxstd=$CXXSTD variant=debug,release ${UBSAN:+cxxflags=-fsanitize=undefined cxxflags=-fno-sanitize-recover=undefined linkflags=-fsanitize=undefined debug-symbols=on} ${LINKFLAGS:+linkflags=$LINKFLAGS}

echo '==================================> AFTER_SUCCESS'

. $DRONE_CURRENT_BUILD_DIR/.drone/after-success.sh
