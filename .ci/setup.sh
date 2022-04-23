#!/bin/bash

if [[ $OS_NAME == "macos" ]]; then
    if  [[ $COMPILER == "clang" ]]; then
        brew install libomp
        if [[ $AZURE == "true" ]]; then
            sudo xcode-select -s /Applications/Xcode_10.3.app/Contents/Developer || exit -1
        fi
    else  # gcc
        if [[ $TASK != "mpi" ]]; then
            brew install gcc
        fi
    fi
    if [[ $TASK == "mpi" ]]; then
        brew install open-mpi
    fi
    if [[ $TASK == "swig" ]]; then
        brew install swig
    fi
    curl \
        -sL \
        -o miniforge.sh \
        https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-x86_64.sh
else  # Linux
    if [[ $IN_UBUNTU_LATEST_CONTAINER == "true" ]]; then
        # fixes error "unable to initialize frontend: Dialog"
        # https://github.com/moby/moby/issues/27988#issuecomment-462809153
        echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections

        sudo apt-get update
        sudo apt-get install --no-install-recommends -y \
            locales \
            software-properties-common

        export LANG="en_US.UTF-8"
        sudo locale-gen ${LANG}
        sudo update-locale LANG=${LANG}

        sudo apt-get install --no-install-recommends -y \
            apt-utils \
            build-essential \
            ca-certificates \
            cmake \
            curl \
            git \
            iputils-ping \
            jq \
            libcurl4 \
            libunwind8 \
            netcat \
            unzip \
            zip || exit -1
        if [[ $COMPILER == "clang" ]]; then
            sudo apt-get install --no-install-recommends -y \
                clang \
                libomp-dev
        fi
    fi
    if [[ $TASK == "mpi" ]]; then
        sudo apt-get update
        sudo apt-get install --no-install-recommends -y \
            libopenmpi-dev \
            openmpi-bin
    fi
    if [[ $TASK == "gpu" ]]; then
        sudo add-apt-repository ppa:mhier/libboost-latest -y
        sudo apt-get update
        sudo apt-get install --no-install-recommends -y \
            libboost1.74-dev \
            ocl-icd-opencl-dev
        cd $BUILD_DIRECTORY  # to avoid permission errors
        curl -sL -o AMD-APP-SDKInstaller.tar.bz2 https://github.com/microsoft/LightGBM/releases/download/v2.0.12/AMD-APP-SDKInstaller-v3.0.130.136-GA-linux64.tar.bz2
        tar -xjf AMD-APP-SDKInstaller.tar.bz2
        mkdir -p $OPENCL_VENDOR_PATH
        mkdir -p $AMDAPPSDK_PATH
        sh AMD-APP-SDK*.sh --tar -xf -C $AMDAPPSDK_PATH
        mv $AMDAPPSDK_PATH/lib/x86_64/sdk/* $AMDAPPSDK_PATH/lib/x86_64/
        echo libamdocl64.so > $OPENCL_VENDOR_PATH/amdocl64.icd
    fi
    if [[ $TASK == "cuda" || $TASK == "cuda_exp" ]]; then
        echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
        apt-get update
        apt-get install --no-install-recommends -y \
            curl \
            lsb-release \
            software-properties-common
        if [[ $COMPILER == "clang" ]]; then
            apt-get install --no-install-recommends -y \
                clang \
                libomp-dev
        fi
        curl -sL https://apt.kitware.com/keys/kitware-archive-latest.asc | apt-key add -
        apt-add-repository "deb https://apt.kitware.com/ubuntu/ $(lsb_release -cs) main" -y
        apt-get update
        apt-get install --no-install-recommends -y \
            cmake
    fi
    if [[ $SETUP_CONDA != "false" ]]; then
        ARCH=$(uname -m)
        curl \
            -sL \
            -o miniforge.sh \
            https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-${ARCH}.sh
    fi
fi

if [[ "${TASK}" != "r-package" ]] && [[ "${TASK}" != "r-rchk" ]]; then
    if [[ $SETUP_CONDA != "false" ]]; then
        sh miniforge.sh -b -p $CONDA
    fi
    conda config --set always_yes yes --set changeps1 no
    conda update -q -y conda
fi
