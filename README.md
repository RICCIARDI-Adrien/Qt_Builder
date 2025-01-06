[![](https://github.com/RICCIARDI-Adrien/Qt_Builder/workflows/Build%20supported%20Qt%20versions/badge.svg)](https://github.com/RICCIARDI-Adrien/Qt_Builder/actions)

# Qt Builder

Allow to easily build latest Qt version from sources on 32 and 64-bit Linux systems.

## Ubuntu/Debian build dependencies

### Qt 5

On Ubuntu/Debian systems, install all Qt 5 required build dependencies with a single command :
```
sudo apt build-dep qt5-default
```

Then, install the following packages :
```
sudo apt install bison flex gperf libclang-dev libdbus-1-dev libnss3-dev libxcb-util-dev libxcb-xinerama0-dev libxcomposite-dev libxcursor-dev libxkbcommon-dev libxtst-dev patchelf
```

### Qt 6

Use a **recent** Ubuntu/Debian distribution (at least Ubuntu 20.04). However, it is also possible to build Qt 6 on Ubuntu 18.04 with some system setup, see below for more information.

Install most of the build dependencies with the following command :
```
sudo apt build-dep qtbase5-dev
```

Then, install the following packages :
```
sudo apt install bison cmake flex gperf libb2-dev libclang-dev libclang-11-dev libclang-12-dev libdbus-1-dev libdirectfb-dev libgstreamer1.0-dev libnss3-dev libsystemd-dev libts-dev libxcb-util-dev libxcb-xinerama0-dev libxcomposite-dev libxcursor-dev libxkbcommon-dev libxcb-composite0-dev libxcb-cursor-dev libxcb-damage0-dev libxcb-dpms0-dev libxcb-dri2-0-dev libxcb-dri3-dev libxcb-ewmh-dev libxcb-present-dev libxcb-record0-dev libxcb-res0-dev libxcb-screensaver0-dev libxcb-xf86dri0-dev libxcb-xtest0-dev libxcb-xv0-dev libxcb-xvmc0-dev libxtst-dev ninja-build patchelf xcb
```

Building on Ubuntu 18.04 :
* Install g++ 8 from the official package repositories and make it the system default compiler :
  ```
  sudo apt install g++-8
  sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-8 20
  ```
* Install a more recent version of CMake from Snaps :
  ```
  sudo snap install cmake --classic
  ```

## Usage

Call `Qt_Builder.sh` script with as mandatory argument the Qt version you want to build (for instance `5.13.0`).  
  
Everything will then be downloaded and built into the `/tmp` directory. At the end of the process, Qt will be installed to `/opt/Qt/<Qt version>`.  

It is also possible to specify the temporary build directory as the second (optional) argument.
