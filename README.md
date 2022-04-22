# [OpenVINO™ Toolkit](https://github.com/openvinotoolkit/openvino) - Prebuilt ARM CPU plugin
[![PyPI](https://img.shields.io/pypi/v/openvino-arm)](https://pypi.org/project/openvino-arm/)

Prebuilt [openvino](https://github.com/openvinotoolkit/openvino) python package with the [openvino arm cpu](https://github.com/openvinotoolkit/openvino_contrib/tree/master/modules/arm_plugin) extension for MacOS. Currently only MacOS `11` and `12` with `arm64` is supported.

## Install
To install the prebuilt packages from [PyPi](https://pypi.org/project/openvino-arm/), use the following command. The package is called openvino-arm but is a drop-in-replacement for the openvino package.

```
pip install openvino-arm
```

### Requirements.txt
To use this library version in a `requirements.txt` it is recommended to use the following structure.

```
openvino-arm; platform_system == "Darwin" and platform.machine == 'arm64'
```

### Numpy Dependency
OpenVINO still depends on numpy version `<1.20` which has no prebuilt Apple silicon binaries ready. Pip tries to download and build it from source, which can fail on an Apple silicon Mac. Because of that the dependency condition has been excluded from this build. OpenVINO runs with deprecation warnings together with numpy `1.22`.

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
