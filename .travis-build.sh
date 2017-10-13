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
  export PROCESSOR=formatter
elif [[ "$1" == "interning" ]]; then
  export PROCESSOR=interning
elif [[ "$1" == "lock" ]]; then
  export PROCESSOR=lock
elif [[ "$1" == "nullness-fbc" ]]; then
  export PROCESSOR=nullness
elif [[ "$1" == "nullness-raw" ]]; then
  export PROCESSOR=org.checkerframework.checker.nullness.NullnessRawnessChecker
elif [[ "$1" == "regex" ]]; then
  export PROCESSOR=regex
elif [[ "$1" == "signature" ]]; then
  export PROCESSOR=signature
elif [[ "$1" == "index" ]]; then
  export PROCESSOR=index
elif [[ "$1" == "value" ]]; then
  export PROCESSOR=org.checkerframework.common.value.ValueChecker
else
  echo "Bad argument '$1' to travis-build.sh"
  false
fi

./build8.sh
