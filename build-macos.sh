#!/bin/bash

# dependencies
# brew install ninja
# brew install wget
# brew install git-lfs

ov_version_tag="2022.1.0"
openvino_dir="openvino"

ov_contrib_version_tag="2022.1"
openvino_contrib_dir="openvino_contrib"

build_dir="ie_build"

# cleanup
rm -rf $build_dir
rm -rf $openvino_dir
rm -rf $openvino_contrib_dir

# download
git clone --recurse-submodules --shallow-submodules --depth 1 --branch $ov_version_tag https://github.com/openvinotoolkit/openvino.git $openvino_dir
git clone --recurse-submodules --shallow-submodules --depth 1 --branch $ov_contrib_version_tag https://github.com/openvinotoolkit/openvino_contrib.git $openvino_contrib_dir

root_dir=$(pwd)

# acl patch
pushd "$openvino_contrib_dir/modules/arm_plugin/thirdparty/ComputeLibrary" || exit
wget "https://review.mlplatform.org/changes/ml%2FComputeLibrary~6706/revisions/4/patch?zip" -O patch.zip
unzip patch.zip
git apply 48f2615.diff
popd || exit

# python packages
pip install wheel
pip install pybind11 cython scons pyyaml clang==9.0

# build
mkdir $build_dir
pushd $build_dir || exit

# find /usr/ -name 'libpython*m.dylib'
# find /usr/ -type d -name python3.7m

cmake -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DENABLE_BEH_TESTS=OFF \
      -DENABLE_CLDNN=OFF \
      -DENABLE_FUNCTIONAL_TESTS=OFF \
      -DENABLE_MKL_DNN=ON \
      -DENABLE_TESTS=OFF \
      -DENABLE_SAMPLES=ON \
      -DENABLE_PYTHON=ON \
      -DENABLE_WHEEL=ON \
      -DENABLE_INTEL_MYRIAD=OFF \
      -DCMAKE_INSTALL_PREFIX="$root_dir/$build_dir" \
      -DPYTHON_EXECUTABLE="$(which python)" \
      -DTHREADING=SEQ \
      -DIE_EXTRA_MODULES="$root_dir/$openvino_contrib_dir/modules/arm_plugin" \
      -DARM_COMPUTE_SCONS_JOBS=4 \
      -DPYTHON_LIBRARY=/Library/Frameworks/Python.framework/Versions/Current/lib \
      "$root_dir/$openvino_dir"

cmake --build . --
# ninja install

# delocate
pip install delocate
delocate-wheel -v ./*.whl

popd || exit