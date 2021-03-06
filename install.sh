#!/bin/bash

set -ex

# realpath might not be available on MacOS
script_path=$(python -c "import os; import sys; print(os.path.realpath(sys.argv[1]))" "${BASH_SOURCE[0]}")
top_dir=$(dirname "$script_path")
REPOS_DIR="$top_dir/repos"
BUILD_DIR="$top_dir/build"
mkdir -p "$BUILD_DIR"

_pip_install() {
    if [[ -n "$CI" ]]; then
        if [[ -z "${SCCACHE_BUCKET}" ]]; then
            ccache -z
        fi
    fi
    if [[ -n "$CI" ]]; then
        time pip install "$@"
    else
        pip install "$@"
    fi
    if [[ -n "$CI" ]]; then
        if [[ -n "${SCCACHE_BUCKET}" ]]; then
            sccache --show-stats
        else
            ccache -s
        fi
    fi
}

# Install caffe2
if [[ -n "$CI" ]]; then
    # TODO: remove this
    rm -rf "$REPOS_DIR/pytorch/third_party/onnx" && cp -r "$REPOS_DIR/onnx" "$REPOS_DIR/pytorch/third_party/onnx"
fi
pip install -r "$REPOS_DIR/pytorch/caffe2/requirements.txt"
cd "$REPOS_DIR/pytorch" && python setup_caffe2.py install && cd -
python -c 'from caffe2.python import build; from pprint import pprint; pprint(build.build_options)'

# Install onnx
_pip_install -b "$BUILD_DIR/onnx" "file://$REPOS_DIR/onnx#egg=onnx"

# Install pytorch
pip install -r "$REPOS_DIR/pytorch/requirements.txt"
_pip_install -b "$BUILD_DIR/pytorch" "file://$REPOS_DIR/pytorch#egg=torch"
