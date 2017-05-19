#!/bin/sh

#  opus.sh
#  
#
#  Created by Abdul Rauf on 18/03/2017.
#

VERSION="1.1.4"
IOS_SDK_VERSION=$(xcodebuild -version -sdk iphoneos | grep SDKVersion | cut -f2 -d ':' | tr -d '[[:space:]]')
DEPLOYMENT_TARGET="8.3"

CURRENTPATH=`pwd`
ARCHS="x86_64 armv7 arm64"
DEVELOPER_TOOL_PATH=`xcode-select -print-path`

#
# Export all variables for a specified architecture
#
setvars_all()
{
export CC="${DEVELOPER_TOOL_PATH}/usr/bin/gcc"
export CXX="${DEVELOPER_TOOL_PATH}/usr/bin/g++"
export CPP="${DEVELOPER_TOOL_PATH}/usr/bin/gcc -E"

if [[ "${ARCH}" =~ arm. ]];
then
export LD=$DEVROOT/usr/bin/ld
export AR=$DEVROOT/usr/bin/ar
export AS=$DEVROOT/usr/bin/as
export NM=$DEVROOT/usr/bin/nm
export RANLIB=$DEVROOT/usr/bin/ranlib
fi

export CXXFLAGS=$CFLAGS
export CPPFLAGS=$CFLAGS
}

#
# Shell script execution begins here
#

echo "----------------------------------------------------------------------------------"
echo "-------------------------- BUILD OPUS CODEC v${VERSION} -------------------------------"
echo "----------------------------------------------------------------------------------"


if [ ! -d "$DEVELOPER_TOOL_PATH" ]; then
echo "xcode path is not set correctly ${IOS_SDK_VERSION} does not exist"
echo "check if you have xcode > 4.3 and command line tools installed"
echo "otherwise follow the steps below"
echo "run"
echo "sudo xcode-select -switch <xcode path>"
echo "for default installation:"
echo "sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer"
exit 1
fi

set -e
if [ ! -e opus-${VERSION}.tar.gz ]; then
echo "Downloading opus-${VERSION}.tar.gz"
curl -O http://downloads.xiph.org/releases/opus/opus-${VERSION}.tar.gz
else
echo "Using opus-${VERSION}.tar.gz"
fi


BIN="${CURRENTPATH}/bin"
SOURCE="${CURRENTPATH}/src"
LIB="${CURRENTPATH}/lib"

mkdir -p ${BIN}
mkdir -p ${SOURCE}
mkdir -p ${LIB}

tar zxf opus-${VERSION}.tar.gz -C "${SOURCE}"
cd "${SOURCE}/opus-${VERSION}"

for ARCH in ${ARCHS}
do

if [[ "${ARCH}" == "i386" || "${ARCH}" == "x86_64" ]];
then
PLATFORM="iPhoneSimulator"
else
PLATFORM="iPhoneOS"
fi

unset DEVROOT SDKROOT CFLAGS CC LD CPP CXX AR AS NM RANLIB CPPFLAGS CXXFLAGS

export DEVROOT="${DEVELOPER_TOOL_PATH}/Toolchains/XcodeDefault.xctoolchain"

export SDKROOT="${DEVELOPER_TOOL_PATH}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${IOS_SDK_VERSION}.sdk"

export CFLAGS="-arch ${ARCH} -isysroot ${SDKROOT} -miphoneos-version-min=${DEPLOYMENT_TARGET}"

setvars_all

echo "Building opus-${VERSION} for ${PLATFORM} ${IOS_SDK_VERSION} ${ARCH}"
echo "Please wait..."

LOG_PATH="${BIN}/${PLATFORM}${IOS_SDK_VERSION}-${ARCH}.sdk"

mkdir -p "${LOG_PATH}"
LOG="${LOG_PATH}/build-opus-${PLATFORM}-${VERSION}.log"


if [ "${ARCH}" == "x86_64" ]; then
./configure --host=arm-apple-darwin --prefix="${CURRENTPATH}/bin/${PLATFORM}${IOS_SDK_VERSION}-${ARCH}.sdk" > "${LOG}" 2>&1
else
./configure --host=arm-apple-darwin --prefix="${CURRENTPATH}/bin/${PLATFORM}${IOS_SDK_VERSION}-${ARCH}.sdk" > "${LOG}" 2>&1
fi

echo "make"
make >> "${LOG}" 2>&1

echo "make install"
make install >> "${LOG}" 2>&1

echo "make clean"
make distclean >> "${LOG}" 2>&1
done

echo "###################  Building universal library  ######################"

lipo -create  ${CURRENTPATH}/bin/iPhoneSimulator${IOS_SDK_VERSION}-x86_64.sdk/lib/libopus.a ${CURRENTPATH}/bin/iPhoneOS${IOS_SDK_VERSION}-armv7.sdk/lib/libopus.a ${CURRENTPATH}/bin/iPhoneOS${IOS_SDK_VERSION}-arm64.sdk/lib/libopus.a -output ${CURRENTPATH}/lib/libopus.a

# Copy over the header files
mkdir -p ${CURRENTPATH}/include
cp -R ${CURRENTPATH}/bin/iPhoneSimulator${IOS_SDK_VERSION}-x86_64.sdk/include/opus ${CURRENTPATH}/include/

unset DEVROOT SDKROOT CFLAGS CC LD CPP CXX AR AS NM RANLIB CPPFLAGS CXXFLAGS
rm -rf ${SOURCE}
rm -rf ${BIN}

echo "Done."

