#!/bin/sh

#  pj_compilation_script_iOS.sh
#  
#
#  Created by Abdul Rauf on 21/05/2017.
#


##############################################

VERSION="2.6"
IOS_SDK_VERSION=$(xcodebuild -version -sdk iphoneos | grep SDKVersion | cut -f2 -d ':' | tr -d '[[:space:]]')
DEPLOYMENT_TARGET="8.3"

###############################################

CURRENTPATH=`pwd`
ARCHS="x86_64 armv7 arm64"
DEVELOPER_TOOL_PATH=`xcode-select -print-path`

###############################################

if [ ! -d "$DEVELOPER_TOOL_PATH" ]; then
echo "xcode path is not set correctly $DEVELOPER_TOOL_PATH does not exist"
echo "check if you have xcode > 4.3 and command line tools installed"
echo "otherwise follow the steps below"
echo "run"
echo "sudo xcode-select -switch <xcode path>"
echo "for default installation:"
echo "sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer"
exit 1
fi

# Build PJSIP
set -e
if [ ! -e pjproject-${VERSION}.tar.bz2 ]; then
echo "No pjproject-${VERSION} is available, we need to checkout first"
curl -O http://www.pjsip.org/release/${VERSION}/pjproject-${VERSION}.tar.bz2
else
echo "Using pjproject-${VERSION}.tar.bz2"
fi


BIN="${CURRENTPATH}/bin"
SOURCE="${CURRENTPATH}/src"
LIB="${CURRENTPATH}/lib"

mkdir -p ${BIN}
mkdir -p ${SOURCE}
mkdir -p ${LIB}

SIPSTACK="${SOURCE}/pjproject-${VERSION}"
mkdir -p ${SIPSTACK}

tar zxf pjproject-${VERSION}.tar.bz2 -C "${SOURCE}"
cd "${SIPSTACK}"

CONFIG_FILE="$SIPSTACK/pjlib/include/pj/config_site.h"

#Setting some Default Configuration for iOS
/bin/cat <<EOM >$CONFIG_FILE
#define PJ_CONFIG_IPHONE 1
#include <pj/config_site_sample.h>
EOM

# Begin compiling
for ARCHI in ${ARCHS}
do

if [[ "${ARCHI}" == "i386" || "${ARCHI}" == "x86_64" ]];
then
PLATFORM="iPhoneSimulator"
export CFLAGS="-m32 -O2 -miphoneos-version-min=${DEPLOYMENT_TARGET}"
export DEVPATH="${DEVELOPER_TOOL_PATH}/Platforms/${PLATFORM}.platform/Developer"
else
PLATFORM="iPhoneOS"
fi

echo ""
echo "Building pjproject-${VERSION} for ${PLATFORM} ${IOS_SDK_VERSION} ${ARCHI}"
echo "Please wait..."

export ARCH="-arch ${ARCHI}"

mkdir -p "${BIN}/${PLATFORM}${IOS_SDK_VERSION}-${ARCHI}.sdk"
LOG="${BIN}/${PLATFORM}${IOS_SDK_VERSION}-${ARCHI}.sdk/build-pjsip-${ARCHI}-${VERSION}.log"


#--with-ssl
#--disable-g729-codec
echo "Opuss Path ${CURRENTPATH}/../opus/lib"

./configure-iphone --prefix="${BIN}/${PLATFORM}${IOS_SDK_VERSION}-${ARCHI}.sdk"  --with-opus="${OPUS_PATH}" --disable-gsm-codec --disable-g7221-codec >> "${LOG}" 2>&1

make >> "${LOG}" 2>&1
make install >> "${LOG}" 2>&1
make clean >> "${LOG}" 2>&1
make distclean >> "${LOG}" 2>&1


unset ARCH DEVPATH CFLAGS

done

echo "Cleaning Up ..."



