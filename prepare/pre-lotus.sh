#!/usr/bin/env bash
#
# This is a Shell script for lotus.
#
# Reference URL:
# https://www.notion.so/134a172e369446018f5067097491550c

cur_dir="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
cur_date="$(date "+%m%d-%H")"

lotus_rep=https://github.com/filecoin-project/lotus.git
branch="master"
git_tag=v1.4.0
rep_dir="lotus-${branch}"

export GO_VERSION=1.15.5

proxy=http://127.0.0.1:7890

export http_proxy=$proxy
export https_proxy=$proxy

git config --global http.proxy $proxy
git config --global https.proxy $proxy
git config --global --add remote.origin.proxy $proxy

_red() {
    printf '\033[1;31;31m%b\033[0m' "$1"
}

_green() {
    printf '\033[1;31;32m%b\033[0m' "$1"
}

_yellow() {
    printf '\033[1;31;33m%b\033[0m' "$1"
}

_printargs() {
    printf -- "%s" "[$(date)] "
    printf -- "%s" "$1"
    printf "\n"
}

_info() {
    _printargs "$@"
}

_warn() {
    printf -- "%s" "[$(date)] "
    _yellow "$1"
    printf "\n"
}

_error() {
    printf -- "%s" "[$(date)] "
    _red "$1"
    printf "\n"
    exit 2
}

_exit() {
    printf "\n"
    _red "$0 has been terminated."
    printf "\n"
    exit 1
}

_error_detect() {
    local cmd="$1"
    _info "${cmd}"
    eval ${cmd} 1> /dev/null
    if [ $? -ne 0 ]; then
        _error "Execution command (${cmd}) failed, please try again."
    fi
}

prepare_apt() {
    _error_detect "apt-get -y update"
    _error_detect "apt-get -y install mesa-opencl-icd ocl-icd-opencl-dev gcc git bzr jq pkg-config curl libhwloc-dev"
}

prepare_go() {
    _error_detect "curl -OL https://golang.google.cn/dl/go${GO_VERSION}.linux-amd64.tar.gz"
    _error_detect "tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz"
}

prepare_rust() {
    _error_detect "curl -sSf https://sh.rustup.rs | sh -s -- -y"
}

# Make bin from source
make_bin() {
    export PATH=$PATH:/usr/local/go/bin:$HOME/.cargo/bin
    export GOPROXY=https://goproxy.cn,direct
    cd $cur_dir
    _error_detect "rm -rf $rep_dir"
    _error_detect "git clone --depth=1 -b $branch $lotus_rep $rep_dir"
    cd $rep_dir
    _error_detect "git fetch --tags --prune"
    _error_detect "git checkout tags/$git_tag"
    # sed -i 's/"check_cpu_for_feature": null/"check_cpu_for_feature": "sha_ni"/g' extern/filecoin-ffi/rust/rustc-target-features-optimized.json
    # for intel CGO_CFLAGS="-D__BLST_PORTABLE__" 
    env LC_ALL=C RUSTFLAGS='-C target-cpu=native -g' FIL_PROOFS_USE_GPU_COLUMN_BUILDER=1 FIL_PROOFS_USE_GPU_TREE_BUILDER=1 FFI_BUILD_FROM_SOURCE=1 make all
}

main() {
    _info "Prepare environment..."
    #prepare_apt
    #prepare_go
    #prepare_rust
    _info "Make lotus from source..."
    make_bin
    _info "Done!"
}

main "$@"