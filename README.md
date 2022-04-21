# [OpenVINO™ Toolkit](https://github.com/openvinotoolkit/openvino) - Prebuilt ARM CPU plugin
Prebuilt [openvino](https://github.com/openvinotoolkit/openvino) python package with the [openvino arm cpu](https://github.com/openvinotoolkit/openvino_contrib/tree/master/modules/arm_plugin) extension for MacOS. Currently only MacOS `11` and `12` with `arm64` is supported.

## Install
To install the prebuilt packages, use the following command. The package is called openvino-arm but is a drop-in-replacement for the openvino package.

```
pip install openvino-arm --find-links https://github.com/cansik/openvino-arm/releases/tag/2022.1.0
```

### Requirements.txt
To use this library version in a `requirements.txt` it is recommended to use the following structure.

```
openvino-arm; platform_system == "Darwin" and platform.machine == 'arm64'
```

### Numpy Dependency
OpenVINO still depends on numpy version `<1.20` which has no prebuilt Apple silicon binaries ready. Pip tries to download and build it from source, which can fail on an Apple silicon Mac.

A fix for now is to install a newer version of numpy and ignore the dependencies for openvino.

```
pip install numpy
pip install --no-deps openvino-arm
```

## Build
To build the libraries yourself, please first install the following dependencies and run the build script.

```
brew install ninja wget git-lfs
```

```
./build-macos.sh
```

The pre-built wheel packages should be in the `dist` directory.

## About
MIT License - Copyright (c) 2022 Florian Bruggisser
