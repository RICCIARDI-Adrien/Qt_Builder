#!/bin/sh

#--------------------------------------------------------------------------------------------------
# Private functions
#--------------------------------------------------------------------------------------------------
function PrintMessage()
{
	printf "\033[33m----------------------------------------------------------------------\n\033[0m"
	printf "\033[33m$1\n\033[0m"
	printf "\033[33m----------------------------------------------------------------------\n\033[0m"
}

# Make sure a Qt version has been provided
QT_VERSION=$1
if [ -z $QT_VERSION ]
then
	printf "Usage : $0 Qt_Version\n"
	printf "For instance, to build Qt 5.12.3 use the following command : $0 5.12.3\n"
	exit 1
fi

# Create build directories
PrintMessage "Creating build environment..."
BUILD_DIRECTORY_PATH="/tmp/Qt_Builder_${QT_VERSION}"
printf "Building to \"${BUILD_DIRECTORY_PATH}\".\n"
printf "Removing previous build artifacts...\n"
rm -rf $BUILD_DIRECTORY_PATH
mkdir -p $BUILD_DIRECTORY_PATH

# Download all required sources
PrintMessage "Downloading Qt sources..."
# Create downloading URL
QT_MAJOR_VERSION=$(echo $QT_VERSION | awk -F "." '{ print $1"."$2 }')
QT_SOURCE_FILE_BASE_NAME=qt-everywhere-src-${QT_VERSION}
QT_SOURCES_URL="http://download.qt.io/archive/qt/${QT_MAJOR_VERSION}/${QT_VERSION}/single/${QT_SOURCE_FILE_BASE_NAME}.tar.xz"
# Download data
wget $QT_SOURCES_URL -O "${BUILD_DIRECTORY_PATH}/${QT_SOURCE_FILE_BASE_NAME}.tar.xz"
if [ $? -ne 0 ]
then
	printf "\033[31mError : source archive downloading failed.\n\033[0m\n"
	exit 2
fi

# Extract sources
PrintMessage "Extracting sources..."
cd $BUILD_DIRECTORY_PATH
tar -xf "${QT_SOURCE_FILE_BASE_NAME}.tar.xz"
cd $QT_SOURCE_FILE_BASE_NAME

# Configure build
PrintMessage "Configuring Qt build..."
./configure -prefix /opt/Qt/$QT_VERSION -opensource -release -confirm-license -nomake tests -nomake examples
if [ $? -ne 0 ]
then
	printf "\033[31mError : failed to configure Qt build.\n\033[0m\n"
	exit 3
fi

# Build everything
PrintMessage "Building..."
PROCESSORS_COUNT=$(cat /proc/cpuinfo  | grep "processor" | wc -l)
make -j $PROCESSORS_COUNT
if [ $? -ne 0 ]
then
	printf "\033[31mError : failed to build Qt.\n\033[0m\n"
	exit 4
fi

# Install Qt
PrintMessage "Installing..."
make install
if [ $? -ne 0 ]
then
	printf "\033[31mError : failed to install Qt.\n\033[0m\n"
	exit 5
fi

# Clean build artifacts
rm -rf $BUILD_DIRECTORY_PATH
PrintMessage "Qt Builder successfully terminated."
