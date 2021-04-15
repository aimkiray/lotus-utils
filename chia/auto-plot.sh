#!/usr/bin/env bash
#
# This is a auto plot script for chia.

PLOT_SIZE=110
PLOT_PATH_LIMIT=7200
CACHE_SIZE=300
CACHE_PATH_LIMIT=14000
PARALLEL_PLOT=24
# chia keys show
FARMER_PK=xxx
POOL_PK=xxx

# NFS mount BASE path
NFS_BASE_PATH=/nfs990
NFS_INDEX_FIRST=1
NFS_INDEX_LAST=1
# Mount BASE path for each drive in the NFS path
# e.g. /nfs23020/test9
DRIVE_BASE_PATH=/test
DRIVE_INDEX_FIRST=1
DRIVE_INDEX_LAST=24
# SSD cache path
CACHE_PATH=/tank1/test

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
    eval ${cmd} 1>/dev/null
    if [ $? -ne 0 ]; then
        _error "Execution command (${cmd}) failed, please try again."
    fi
}

_error_detect "cd /root/chia-blockchain/"
_error_detect ". ./activate"
# _error_detect "mkdir -p $CACHE_PATH"

while true; do

    if [ ! -d $CACHE_PATH ]; then
        _error "Cache path $CACHE_PATH 404, self explosion."
    fi

    CACHE_PATH_LIMIT_TRUE=$(df -P $CACHE_PATH | awk 'NR==2 {print $2}')
    CACHE_PATH_LIMIT_TRUE=$(($CACHE_PATH_LIMIT_TRUE / 1024 / 1024))
    if [ $CACHE_PATH_LIMIT_TRUE -lt $CACHE_PATH_LIMIT ]; then
        (($CACHE_PATH_LIMIT = $CACHE_PATH_LIMIT_TRUE))
        _warn "The real capacity of cache is ${CACHE_PATH_LIMIT_TRUE}GB, but the configuration is ${CACHE_PATH_LIMIT}GB"
    fi

    # Loop NFS path
    for ((i = $NFS_INDEX_FIRST; i <= $NFS_INDEX_LAST; i++)); do

        # Loop drive path
        for ((j = $DRIVE_INDEX_FIRST; j <= $DRIVE_INDEX_LAST; j++)); do

            TARGET_PATH=$NFS_BASE_PATH$i$DRIVE_BASE_PATH$j
            # mkdir -p $TARGET_PATH
            if [ ! -d $TARGET_PATH ]; then
                _warn "Target path $TARGET_PATH 404, pass."
                continue
            fi

            CUR_PLOT=$(ps -ef | grep "chia plots create" | grep -v grep | wc -l)
            if [ $CUR_PLOT -ge $PARALLEL_PLOT ]; then
                _warn "Currently $CUR_PLOT parallel plot is overload, sleep."
                break
            fi

            # Calculate the cache required for all running plots.
            CACHE_PATH_SIZE=$(df -P $CACHE_PATH | awk 'NR==2 {print $3}')
            CACHE_PATH_SIZE=$(($CACHE_PATH_SIZE / 1024 / 1024))
            CACHE_RUNING_OCC=$(($CUR_PLOT * $CACHE_SIZE))
            CACHE_PATH_SIZE_REMAIN=$(($CACHE_PATH_LIMIT - $CACHE_PATH_SIZE - $CACHE_RUNING_OCC))

            if [ $CACHE_PATH_SIZE_REMAIN -le $CACHE_SIZE ]; then
                _warn "Insufficient cache path space, sleep."
                break
            fi

            # Calculate the space required for all running plots.
            mkdir -p $TARGET_PATH/planned
            TARGET_PATH_OCC=$(ls -l $TARGET_PATH/planned | grep plot | wc -l)
            TARGET_PATH_OCC_SIZE=$(($TARGET_PATH_OCC * $PLOT_SIZE))
            TARGET_PATH_OCC_SIZE_REMAIN=$(($PLOT_PATH_LIMIT - $TARGET_PATH_OCC_SIZE))

            if [ $TARGET_PATH_OCC_SIZE_REMAIN -le $PLOT_SIZE ]; then
                _warn "The $TARGET_PATH is full, $TARGET_PATH_OCC plots planned."
                continue
            fi

            PLOT_PATH_LIMIT_TRUE=$(df -P $TARGET_PATH | awk 'NR==2 {print $2}')
            PLOT_PATH_LIMIT_TRUE=$(($PLOT_PATH_LIMIT_TRUE / 1024 / 1024))
            if [ $PLOT_PATH_LIMIT_TRUE -lt $PLOT_PATH_LIMIT ]; then
                (($PLOT_PATH_LIMIT = $PLOT_PATH_LIMIT_TRUE))
                _warn "The real capacity of plot path is ${PLOT_PATH_LIMIT_TRUE}GB, but the configuration is ${PLOT_PATH_LIMIT}GB"
            fi

            # Calculate the space for all existing plots.
            TARGET_PATH_SIZE=$(df -P $TARGET_PATH | awk 'NR==2 {print $3}')
            TARGET_PATH_SIZE=$(($TARGET_PATH_SIZE / 1024 / 1024))
            TARGET_PATH_SIZE_ALL=$(($TARGET_PATH_SIZE + $TARGET_PATH_OCC_SIZE))
            TARGET_PATH_SIZE_REMAIN=$(($PLOT_PATH_LIMIT - $TARGET_PATH_SIZE_ALL))

            if [ $TARGET_PATH_SIZE_REMAIN -le $PLOT_SIZE ]; then
                _warn "The $TARGET_PATH is full, ${TARGET_PATH_SIZE}GB plots exist."
                continue
            fi

            # Launch a plot.
            CUR_TIME=$(date "+%Y%m%d-%H%M%S")
            mkdir -p log
            nohup chia plots create -n 1 -u 64 -r 2 -k 32 -b 8000 -t $CACHE_PATH -d $TARGET_PATH -f $FARMER_PK -p $POOL_PK >>log/plot-$CUR_TIME.log 2>&1 &
            _info "Plot will be placed in the ${TARGET_PATH} directory."

            # Get plot ID.
            sleep 3s
            PLOT_ID=$(cat log/plot-$CUR_TIME.log | grep -A 1 "Starting plotting progress into temporary dirs" | grep "ID:" | awk '{ print $NF }')

            if [ -z "$PLOT_ID" ]; then
                _error "Please do chia init first."
            fi

            # Placeholder.
            _error_detect "touch $TARGET_PATH/planned/plot-$PLOT_ID-$CUR_TIME"
            _info "Plot at $TARGET_PATH, ${TARGET_PATH_SIZE_REMAIN}GB remaining."

            # +lucky
            sleep ${RANDOM:0:1}
        done
        # +1s
        sleep ${RANDOM:0:1}
    done
    # +1s
    sleep ${RANDOM:0:1}
done
