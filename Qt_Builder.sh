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
printf "| Qt Builder (C) 2019-2025 Adrien RICCIARDI |\n"
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

# Make sure some tools versions are recent enough for Qt 6
if [ ${QT_VERSION_MAJOR} -eq 6 ]
then
	# CMake version
	CMAKE_VERSION=$(cmake --version | head -n 1 | cut -d ' ' -f 3)
	CMAKE_VERSION_MAJOR=$(echo $CMAKE_VERSION | cut -d '.' -f 1)
	CMAKE_VERSION_MINOR=$(echo $CMAKE_VERSION | cut -d '.' -f 2)
	if [[ ${CMAKE_VERSION_MAJOR} -lt 3 || (${CMAKE_VERSION_MAJOR} -eq 3 && ${CMAKE_VERSION_MINOR} -lt 16) ]]
	then
		printf "\033[31mError : CMake version must be greater or equal to 3.16.\n\033[0m\n"
		exit 1
	fi

	# G++ version
	GPLUSPLUS_VERSION=$(g++ --version | head -n 1 | cut -d ' ' -f 4)
	GPLUSPLUS_VERSION_MAJOR=$(echo $GPLUSPLUS_VERSION | cut -d '.' -f 1)
	if [ ${GPLUSPLUS_VERSION_MAJOR} -lt 8 ]
	then
		printf "\033[31mError : G++ version must be greater or equal to 8.\n\033[0m\n"
		exit 1
	fi
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
# Create the downloading URL
# Start with the "normal" URL Qt has been using for years
QT_ARCHIVE_FILE_NAME=qt-everywhere-src-${QT_VERSION}.tar.xz
QT_SOURCES_URL="https://download.qt.io/archive/qt/${QT_VERSION_MAJOR}.${QT_VERSION_MINOR}/${QT_VERSION}/single/${QT_ARCHIVE_FILE_NAME}"
# Download data
wget $QT_SOURCES_URL -O "${BUILD_DIRECTORY_PATH}/${QT_ARCHIVE_FILE_NAME}"
if [ $? -ne 0 ]
then
	printf "\033[35mWarning : source archive downloading failed, trying the special URL for LTS releases.\n\033[0m\n"

	# Try with the special URL for the LTS releases that Qt Company is blocking behind a paywall (only the versions released as open source will be available)
	QT_ARCHIVE_FILE_NAME=qt-everywhere-opensource-src-${QT_VERSION}.tar.xz
	QT_SOURCES_URL="https://download.qt.io/archive/qt/${QT_VERSION_MAJOR}.${QT_VERSION_MINOR}/${QT_VERSION}/single/${QT_ARCHIVE_FILE_NAME}"
	wget $QT_SOURCES_URL -O "${BUILD_DIRECTORY_PATH}/${QT_ARCHIVE_FILE_NAME}"
	if [ $? -ne 0 ]
	then
		printf "\033[31mError : source archive downloading failed.\n\033[0m\n"
		exit 2
	fi
fi

# Extract sources
PrintMessage "Extracting sources..."
cd $BUILD_DIRECTORY_PATH
tar -xf "${QT_ARCHIVE_FILE_NAME}"
cd qt-everywhere-src-${QT_VERSION}

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
# Statically link the OpenSSL version that Qt desires to avoid compatibility issues on deployed systems
./configure -prefix /opt/Qt/$QT_VERSION -opensource -release -confirm-license -nomake tests -nomake examples -skip qtwebengine -openssl-linked $QT_CONFIGURATION_FLAGS
if [ $? -ne 0 ]
then
	printf "\033[31mError : failed to configure Qt build.\n\033[0m\n"
	exit 3
fi

# Build everything
PrintMessage "Building..."
if [ ${QT_VERSION_MAJOR} -eq 5 ]
then
	BUILD_COMMAND="make -j $(nproc)"
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

# Download linuxdeploy
PrintMessage "Downloading linuxdeploy sources..."
sudo wget https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage -O /usr/bin/linuxdeploy.AppImage
if [ $? -ne 0 ]
then
	printf "\033[31mError : failed to download linuxdeploy to /usr/bin.\n\033[0m\n"
	exit 6
fi
sudo chmod +x /usr/bin/linuxdeploy.AppImage

# Download linuxdeploy Qt plugin
PrintMessage "Downloading linuxdeploy Qt plugin sources..."
sudo wget https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-x86_64.AppImage -O /usr/bin/linuxdeploy-plugin-qt.AppImage
if [ $? -ne 0 ]
then
	printf "\033[31mError : failed to download linuxdeploy Qt plugin to /usr/bin.\n\033[0m\n"
	exit 7
fi
sudo chmod +x /usr/bin/linuxdeploy-plugin-qt.AppImage

# Clean build artifacts
rm -rf $BUILD_DIRECTORY_PATH
PrintMessage "Qt Builder successfully terminated."
