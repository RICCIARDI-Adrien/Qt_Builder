# Qt Builder

Allow to easily build latest Qt version from sources on 32 and 64-bit Linux systems.

## Ubuntu/Debian build dependencies

On Ubuntu/Debian systems, install all Qt 5 required build dependencies with a single command :
```
sudo apt build-dep qt5-default
```

Then, install the following packages :
```
sudo apt install bison flex gperf libclang-dev libdbus-1-dev libnss3-dev libxcb-util-dev libxcb-xinerama0-dev libxcomposite-dev libxcursor-dev libxkbcommon-dev libxtst-dev patchelf
```

## Usage

Call `Qt_Builder.sh` script with as unique argument the Qt version you want to build (for instance `5.13.0`).  
  
Everything will then be downloaded and built into `/tmp` directory. At the end of the process, Qt will be installed to `/opt/Qt/<Qt version>`.
