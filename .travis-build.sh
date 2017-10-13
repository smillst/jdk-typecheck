#!/bin/bash
ROOT=$TRAVIS_BUILD_DIR/..

# Required argument $1 is one of:
#   formatter, interning, lock, nullness, regex, signature, value



## Build Checker Framework
(cd $ROOT && git clone --depth 1  https://github.com/typetools/checker-framework.git)
# This also builds annotation-tools and jsr308-langtools
(cd $ROOT/checker-framework/ && ./.travis-build-without-test.sh downloadjdk)
export CHECKERFRAMEWORK=$ROOT/checker-framework

## Obtain annotated-jdk8u-jdk
(cd $ROOT && hg clone https://bitbucket.org/typetools/annotated-jdk8u-jdk)

## Jdk

if [[ "$1" == "formatter" ]]; then
  PROCESSOR=formatter ./build8.sh
elif [[ "$1" == "interning" ]]; then
  PROCESSOR=interning ./build8.sh
elif [[ "$1" == "lock" ]]; then
  PROCESSOR=lock ./build8.sh
elif [[ "$1" == "nullness-fbc" ]]; then
  PROCESSOR=nullness ./build8.sh
elif [[ "$1" == "nullness-raw" ]]; then
  PROCESSOR=org.checkerframework.checker.nullness.NullnessRawnessChecker ./build8.sh
elif [[ "$1" == "regex" ]]; then
  PROCESSOR=regex ./build8.sh
elif [[ "$1" == "signature" ]]; then
  PROCESSOR=signature ./build8.sh
elif [[ "$1" == "index" ]]; then
  PROCESSOR=index ./build8.sh
elif [[ "$1" == "value" ]]; then
  PROCESSOR=org.checkerframework.common.value.ValueChecker ./build8.sh
else
  echo "Bad argument '$1' to travis-build.sh"
  false
fi

