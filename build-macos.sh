#!/bin/bash

# dependencies
# brew install ninja wget git-lfs

ov_version_tag="2022.1.0"
openvino_dir="openvino"

ov_contrib_version_tag="2022.1"
openvino_contrib_dir="openvino_contrib"

build_dir="ie_build"

# set wheel parameter
export WHEEL_PACKAGE_NAME="openvino-arm"
export WHEEL_URL="https://github.com/cansik/openvino-arm"

# cleanup
rm -rf $build_dir
rm -rf $openvino_dir
rm -rf $openvino_contrib_dir

# download
git clone --recurse-submodules --shallow-submodules --depth 1 --branch $ov_version_tag https://github.com/openvinotoolkit/openvino.git $openvino_dir
git clone --recurse-submodules --shallow-submodules --depth 1 --branch $ov_contrib_version_tag https://github.com/openvinotoolkit/openvino_contrib.git $openvino_contrib_dir

root_dir=$(pwd)
dist_dir="$root_dir/dist"

# acl patch
pushd "$openvino_contrib_dir/modules/arm_plugin/thirdparty/ComputeLibrary" || exit
wget "https://review.mlplatform.org/changes/ml%2FComputeLibrary~6706/revisions/4/patch?zip" -O patch.zip
unzip patch.zip
git apply 48f2615.diff
popd || exit

# arm64 patch
pushd "$openvino_dir" || exit
git apply "$root_dir/arm64-11542.diff"
popd || exit

# python packages
pip install wheel
pip install pybind11 cython scons pyyaml clang==9.0
pip install --upgrade setuptools

# build
mkdir $build_dir
pushd $build_dir || exit

python_executable="$(which python)"
python_root="$(dirname "$python_executable")/.."

pyenv_config="$python_root/pyvenv.cfg"
if test -f "$pyenv_config"; then
  echo "pyenv detected"
  pyenv_home_line="$(head -1 "$pyenv_config")"
  pyenv_home="$(echo "$pyenv_home_line" | awk -F' = ' '{print $2}')/.."
  python_root="$pyenv_home"
fi

python_root="$(readlink -f $python_root)"
python_lib_path="$python_root/lib"
python_lib="$python_lib_path/$(ls "$python_lib_path" | grep libpython)"

echo "Python Executable: $python_executable"
echo "Python Lib: $python_lib"

cmake -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=ON \
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
      -DTHREADING=SEQ \
      -DIE_EXTRA_MODULES="$root_dir/$openvino_contrib_dir/modules/arm_plugin" \
      -DARM_COMPUTE_SCONS_JOBS=4 \
      -DPYTHON_EXECUTABLE="$python_executable" \
      -DPYTHON_LIBRARY="$python_lib" \
      "$root_dir/$openvino_dir"

cmake --build . --
# ninja install

# delocate
# pip install delocate
# delocate-wheel -v ./wheels/*.whl

mkdir -p "$dist_dir"
cp -a ./wheels/*.whl "$dist_dir"

popd || exit
