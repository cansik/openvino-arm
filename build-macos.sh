#!/bin/bash

# dependencies
# brew install ninja wget git-lfs

function find_python() {
  python_executable="$(which python)"
  python_root="$(dirname "$python_executable")/.."

  pyenv_config="$python_root/pyvenv.cfg"
  if test -f "$pyenv_config"; then
    echo "pyenv detected"
    pyenv_home_line="$(head -1 "$pyenv_config")"
    pyenv_root_bin_dir="$(echo "$pyenv_home_line" | awk -F' = ' '{print $2}')"
    pyenv_root_executables="$(ls "$pyenv_root_bin_dir" | grep "^python.*$")"
    pyenv_root_executable_list=${pyenv_root_executables%$'\n'*}

    while IFS= read -r line; do
      pyenv_root_executable="$pyenv_root_bin_dir/$line"
      echo "checking python executable $line..."
      result="$("$pyenv_root_executable" --version)"
      if [ "$result" = "$(python --version)" ]; then
        echo "python executable found: $pyenv_root_executable"
        break
      fi
    done <<< "$pyenv_root_executable_list"

    # lookup link
    pyenv_root_executable="$(readlink -f $pyenv_root_executable)"
    pyenv_root_bin_dir=$(dirname "$pyenv_root_executable")

    python_root="$pyenv_root_bin_dir/.."
  fi

  export python_root="$(readlink -f $python_root)"
  python_lib_path="$python_root/lib"
  export python_lib="$python_lib_path/$(ls "$python_lib_path" | grep libpython)"
}

echo "building for $(python --version)"

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

# prepare build
mkdir $build_dir
pushd $build_dir || exit

# find python
find_python
echo "Python Executable: $python_executable"
echo "Python Lib: $python_lib"

# prepare cmake
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
      -DCMAKE_OSX_DEPLOYMENT_TARGET=11 \
      "$root_dir/$openvino_dir"

cmake --build . --

# warning: ninja install does not work correctly
# ninja install

# read -p "Press enter to continue"

# delocate
# pip install delocate
# delocate-wheel -v ./wheels/*.whl

# fix rpath in infernece engine and constants
pushd ./wheels || exit
wheel_name="$(echo "$WHEEL_PACKAGE_NAME" | awk '{gsub("-","_"); print}')"
openvino_wheel="$(ls | grep "$wheel_name")"
wheel unpack "$openvino_wheel"
wheel_dir_name="$(ls -d ./*/ | grep $wheel_name)"

pushd "$wheel_dir_name/openvino/inference_engine" || exit
install_name_tool -change @rpath/libopenvino.dylib  @loader_path/../libs/libopenvino.dylib ie_api.so
install_name_tool -change @rpath/libopenvino.dylib  @loader_path/../libs/libopenvino.dylib constants.so
popd || exit

wheel pack "$wheel_dir_name"
rm -rf "$wheel_dir_name"

# rename wheel with correct tag and abi
python_tag="$(python -c 'import sys; i=sys.version_info; print(f"cp{i.major}{i.minor}")')"
for file in *.whl ; do mv "$file" "${file//py3-none-macosx_12_0/$python_tag-$python_tag-macosx_11_0}" ; done

popd || exit

mkdir -p "$dist_dir"
cp -a ./wheels/*.whl "$dist_dir"

popd || exit
