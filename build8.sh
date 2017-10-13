#!/bin/sh

# ensure CHECKERFRAMEWORK set
if [ -z "$CHECKERFRAMEWORK" ] ; then
    if [ -z "$CHECKER_FRAMEWORK" ] ; then
        export CHECKERFRAMEWORK=`(cd "$0/../.." && pwd)`
    else
        export CHECKERFRAMEWORK=${CHECKER_FRAMEWORK}
    fi
fi
[ $? -eq 0 ] || (echo "CHECKERFRAMEWORK not set; exiting" && exit 1)

# Compile all packages by default.
${PACKAGES:="com java javax jdk org sun"}


# parameters derived from environment
# TOOLSJAR and CTSYM derived from JAVA_HOME, rest from CHECKERFRAMEWORK
JSR308="`cd $CHECKERFRAMEWORK/.. && pwd`"   # base directory
WORKDIR="${CHECKERFRAMEWORK}/checker/jdk"   # working directory
AJDK="${JSR308}/annotated-jdk8u-jdk"        # annotated JDK
SRCDIR="${AJDK}/src/share/classes"
BINDIR="${WORKDIR}/build"
BOOTDIR="${WORKDIR}/bootstrap"              # initial build w/o processors
TOOLSJAR="${JAVA_HOME}/lib/tools.jar"
LT_BIN="${JSR308}/jsr308-langtools/build/classes"
LT_JAVAC="${JSR308}/jsr308-langtools/dist/bin/javac"
CF_BIN="${CHECKERFRAMEWORK}/checker/build"
CF_DIST="${CHECKERFRAMEWORK}/checker/dist"
CF_JAR="${CF_DIST}/checker.jar"
CF_JAVAC="java -Xmx512m -jar ${CF_JAR} -Xbootclasspath/p:${BOOTDIR}"
CP="${BINDIR}:${BOOTDIR}:${LT_BIN}:${TOOLSJAR}:${CF_BIN}:${CF_JAR}"
JFLAGS="-XDignore.symbol.file=true -Xmaxerrs 20000 -Xmaxwarns 20000\
 -source 8 -target 8 -encoding ascii -cp ${CP}"
PROCESSORS="org.checkerframework.common.value.ValueChecker"
#PROCESSORS="nullness"
PFLAGS="-Anocheckjdk -Aignorejdkastub -AuseDefaultsForUncheckedCode=source\
 -AprintErrorStack -Awarns -Afilenames  -AsuppressWarnings=all "

##Not working on Travis for some reason
#set -o pipefail

rm -rf ${BOOTDIR} ${BINDIR} ${WORKDIR}/log
mkdir -p ${BOOTDIR} ${BINDIR} ${WORKDIR}/log
cd ${SRCDIR}

DIRS=`find $PACKAGES \( -name META_INF -o -name dc\
 -o -name example -o -name jconsole -o -name pept -o -name snmp\
 -o -name internal -o -name security \) -prune -o -type d -print`
SI_DIRS=`find java javax jdk org com sun \( -name META_INF -o -name dc\
 -o -name example -o -name jconsole -o -name pept -o -name snmp \) -prune\
 -o -type d \( -name internal -o -name security \) -print`

## Is this needed??
# The bootstrap JDK, built from the same source as the final result but
# without any Checker Framework processors, obviates building the entire
# JDK source distribution.  You don't want to build the JDK from source.
#echo "build bootstrap JDK"
#find ${SI_DIRS} ${DIRS} -maxdepth 1 -name '*\.java' -print | xargs\
# ${LT_JAVAC} -g -d ${BOOTDIR} ${JFLAGS} -source 8 -target 8 -encoding ascii\
# -cp ${CP} | tee ${WORKDIR}/log/0.log
#[ $? -ne 0 ] && exit 1
#grep -q 'not found' ${WORKDIR}/log/0.log
#(cd ${BOOTDIR} && jar cf ../jdk.jar *)

# These packages are interdependent and cannot be compiled individually.
# Compile them all together.
echo "build internal and security packages"
find ${SI_DIRS} -maxdepth 1 -name '*\.java' -print | xargs\
 ${CF_JAVAC} -g -d ${BINDIR} ${JFLAGS} -processor ${PROCESSORS} ${PFLAGS}\
 | tee ${WORKDIR}/log/1.log
[ $? -ne 0 ] && exit 1

# Build the remaining packages one at a time because building all of
# them together makes the compiler run out of memory.
echo "typecheck"
JAVA_FILES_ARG_FILE=${WORKDIR}/log/args.txt
for d in ${DIRS} ; do
    ls $d/*.java 2>&1 /dev/null || continue
    ls $d/*.java >> ${JAVA_FILES_ARG_FILE}
done
${CF_JAVAC} -g -d ${BINDIR} ${JFLAGS} -processor ${PROCESSORS} ${PFLAGS}\
 @${JAVA_FILES_ARG_FILE} 2>&1 | tee ${WORKDIR}/log/`echo "$d" | tr / .`.log

# Check logfiles for errors and list any source files that failed to
# compile.
grep 'Compilation unit: ' ${WORKDIR}/log/*
if [ $? -ne 1 ] ; then
    exit 1
fi
