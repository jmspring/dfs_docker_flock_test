#!/bin/bash

# This bash script attempts to establish exclusive control over
# a subdirectory to FS_PATH.  This is done by first looking for
# a missing directory and then creating it and generating a 
# lockfile.  Failing that, the next step is that it will try
# existing directories in the range of 0..NODE_COUNT, exclusive.
[ -z "$FS_PATH" ] && echo "Need to set FS_PATH" && exit 1;
[ -z "$NODE_COUNT" ] && echo "Need to set NODE_COUNT" && exit 1;

LOCKFILE="dfs.lock"

if [ ! -d "$FS_PATH" ]; then
    mkdir -p "$FS_PATH"
fi

lock_data_dir() {
    if [ -z $1 ]; then
        echo "Directory must be specified."
        return 1
    fi
    
    WORKINGDIR=$1
    cd $1
    if [ $? -ne 0 ]; then
        echo "Unable to change into directory $WORKINGDIR"
        return 1
    fi
    
    echo "Attempting to lock: $WORKINGDIR/$LOCKFILE"
    exec 200>> "$WORKINGDIR/$LOCKFILE"
    flock -n 200
    if [ $? -ne 0 ]; then
        echo "Unable to lock."
        exec 200>&-
        return 1;
    else
        date 1>&200
        echo "Lock acquired.  Going into endless sleep."
        while ((1)); do
            sleep 10
        done
    fi
}

# check for missing directory
typeset -i i END
let END=$NODE_COUNT i=0 1

while ((i<END)); do
    DATADIR="$FS_PATH/$i"
    echo "Attempting $DATADIR"
    if [ ! -d "$DATADIR" ]; then
        r=`mkdir "$DATADIR"`
        if [ $? -eq 0 ]; then
            lock_data_dir "$DATADIR"
            if [ $? -ne 0 ]; then
                echo "Error locking directory."
            fi
        else
            if [ ! -d "$DATADIR" ]; then
                echo "Unable to create directory.  System error."
                exit 1
            else
                echo "Another process already created directory."
            fi
        fi
    else
        echo "Directory already taken."
    fi
    let i++ 1
done

# if no directory missing, attempt to grab a currently unused but
# setup directory.
let i=0 1
while ((i<END)); do
    DATADIR="$FS_PATH/$i"
    echo "Attempting $DATADIR"
    if [ ! -d "$DATADIR" ]; then
        echo "$DATADIR does not exist.  It should."
        exit 1
    fi
    
    lock_data_dir "$DATADIR"
    if [ $? -ne 0 ]; then
        echo "Unable to lock directory."
    fi
    
    let i++ 1
done

echo "Attempt to lock a directory failed.  Exiting."

