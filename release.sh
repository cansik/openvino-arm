#!/bin/bash

function build ()
{
    echo "Sourcing $1"
    source "$1/bin/activate"
    python --version
    ./build-macos.sh
    deactivate
}

build venv38
build venv39
build venv310