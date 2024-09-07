#!/bin/bash

perdir=$(dirname $(realpath $BASH_SOURCE))
cd $perdir

if [ -z "$VIRTUAL_ENV" ] ; then
    echo "Must run in a virtual env, making one now."
    echo "layout python" > .envrc
    exit 1
fi

set -e
set -x



pip install pyinstaller
for main in rephile herbie
do
    if [ ! -f $main/requirements.txt ] ; then
        continue
    fi
    cd $main
    pip install -r requirements.txt
    cd -
done
for main in rephile herbie
do
    if [ -f $main/$main/__main__.py ] ; then
        pyinstaller --onefile -n $main $main/$main/__main__.py
    elif [ -f $main/${main}.py ] ; then
        pyinstaller --onefile -n $main $main/${main}.py
    else
        echo "SKIPPING package $main, does not fit any pattern."
        continue
    fi
    cp dist/$main ~/sync/bin/
done
