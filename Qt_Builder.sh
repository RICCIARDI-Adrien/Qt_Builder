#!/bin/bash

#--------------------------------------------------------------------------------------------------
# Private functions
#--------------------------------------------------------------------------------------------------
PrintMessage()
{
	printf "\033[33m----------------------------------------------------------------------\033[0m\n"
	printf "\033[33m$1\033[0m\n"
	printf "\033[33m----------------------------------------------------------------------\033[0m\n"
}

#--------------------------------------------------------------------------------------------------
# Entry point
#--------------------------------------------------------------------------------------------------
# Display banner
printf "+-------------------------------------------+\n"
printf "| Qt Builder (C) 2019-2021 Adrien RICCIARDI |\n"
printf "+-------------------------------------------+\n"

# Make sure a Qt version has been provided
QT_VERSION=$1
if [ -z $QT_VERSION ]
then
	printf "Usage : $0 Qt_Version\n"
	printf "For instance, to build Qt 5.12.3 use the following command : $0 5.12.3\n"
	exit 1
fi

# Extract Qt version fields
QT_VERSION_MAJOR=$(echo $QT_VERSION | cut -d '.' -f 1)
QT_VERSION_MINOR=$(echo $QT_VERSION | cut -d '.' -f 2)
QT_VERSION_PATCH=$(echo $QT_VERSION | cut -d '.' -f 3)

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
QT_SOURCE_FILE_BASE_NAME=qt-everywhere-src-${QT_VERSION}
QT_SOURCES_URL="https://download.qt.io/archive/qt/${QT_VERSION_MAJOR}.${QT_VERSION_MINOR}/${QT_VERSION}/single/${QT_SOURCE_FILE_BASE_NAME}.tar.xz"
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
# XCB options have been modified starting from Qt 5.15
if [[ (${QT_VERSION_MAJOR} -eq 5 && ${QT_VERSION_MINOR} -eq 15) || ${QT_VERSION_MAJOR} -eq 6 ]]
then
	QT_CONFIGURATION_FLAGS="-bundled-xcb-xinput -xcb"
else
	QT_CONFIGURATION_FLAGS="-qt-xcb"
fi
# Qt versions before Qt 5.13 do not know about gold linker
if [[ (${QT_VERSION_MAJOR} -eq 5 && ${QT_VERSION_MINOR} -ge 13) || ${QT_VERSION_MAJOR} -eq 6 ]]
then
	QT_CONFIGURATION_FLAGS="${QT_CONFIGURATION_FLAGS} -linker gold"
fi
# Do not build QWebEngine as it requires too much RAM to succeed without modification on a 32-bit system
./configure -prefix /opt/Qt/$QT_VERSION -opensource -release -confirm-license -nomake tests -nomake examples -skip qtwebengine $QT_CONFIGURATION_FLAGS
if [ $? -ne 0 ]
then
	printf "\033[31mError : failed to configure Qt build.\n\033[0m\n"
	exit 3
fi

# Build everything
PrintMessage "Building..."
if [ ${QT_VERSION_MAJOR} -eq 5 ]
then
	PROCESSORS_COUNT=$(cat /proc/cpuinfo  | grep "processor" | wc -l)
	BUILD_COMMAND="make -j $PROCESSORS_COUNT"
else
	BUILD_COMMAND="ninja"
fi
eval $BUILD_COMMAND
if [ $? -ne 0 ]
then
	printf "\033[31mError : failed to build Qt.\n\033[0m\n"
	exit 4
fi

# Install Qt
PrintMessage "Installing Qt..."
if [ ${QT_VERSION_MAJOR} -eq 5 ]
then
	INSTALL_COMMAND="sudo make install"
else
	INSTALL_COMMAND="sudo cmake --install ."
fi
eval $INSTALL_COMMAND
if [ $? -ne 0 ]
then
	printf "\033[31mError : failed to install Qt.\n\033[0m\n"
	exit 5
fi

# Download linuxdeployqt sources
PrintMessage "Downloading linuxdeployqt sources..."
cd $BUILD_DIRECTORY_PATH
git clone https://github.com/probonopd/linuxdeployqt
if [ $? -ne 0 ]
then
	printf "\033[31mError : failed to clone linuxdeployqt repository.\n\033[0m\n"
	exit 6
fi

# Build linuxdeployqt
PrintMessage "Building linuxdeployqt..."
# Configure project
cd ${BUILD_DIRECTORY_PATH}/linuxdeployqt
/opt/Qt/${QT_VERSION}/bin/qmake
if [ $? -ne 0 ]
then
	printf "\033[31mError : failed to configure linuxdeployqt.\n\033[0m\n"
	exit 7
fi
# Build it
make
if [ $? -ne 0 ]
then
	printf "\033[31mError : failed to build linuxdeployqt.\n\033[0m\n"
	exit 8
fi

# Install linuxdeployqt
PrintMessage "Installing linuxdeployqt..."
cd ${BUILD_DIRECTORY_PATH}/linuxdeployqt
sudo make install
if [ $? -ne 0 ]
then
	printf "\033[31mError : failed to install linuxdeployqt.\n\033[0m\n"
	exit 9
fi
# Make linuxdeployqt available from everywhere
sudo ln -sf /opt/Qt/${QT_VERSION}/bin/linuxdeployqt /usr/bin/linuxdeployqt

# Clean build artifacts
rm -rf $BUILD_DIRECTORY_PATH
PrintMessage "Qt Builder successfully terminated."
