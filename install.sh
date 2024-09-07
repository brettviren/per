#!/bin/bash

perdir=$(dirname $(realpath $BASH_SOURCE))
cd $perdir

if [ -z "$VIRTUAL_ENV" ] ; then
    echo "Must run in a virtual env, making one now."
    echo "layout python" > .envrc
    exit 1
fi

set -e

pip install pyinstaller > $perdir/logs/pip-install.log 2>&1

do_install () {
    main=$1 ; shift
    echo "installing $main" 
    
    logd=$perdir/logs/$main
    if [ ! -d $logd ] ; then
        mkdir -p $logd
    fi

    # rm -rf build dist ${main}.spec

    if [ -f $main/requirements.txt ] ; then
        cd $main
        pip install -r requirements.txt > $logd/pip-install.log 2>&1
        cd ..
    fi

    args="--onefile -n $main"
    for mod in $@
    do
        args="$args --hidden-imports $mod"
    done

    mainsrc=""
    if [ -f $main/$main/__main__.py ] ; then
        mainsrc="$main/$main/__main__.py"
    elif [ -f $main/${main}.py ] ; then
        mainsrc="$main/${main}.py"
    else
        echo "SKIPPING package $main, does not fit any pattern."
        return
    fi
    # echo pyinstaller $args $mainsrc
    pyinstaller $args $mainsrc >> $logd/pyinstaller.log 2>&1

    if [ -f dist/$main ] ; then
        # remove first to avoid "Text file is busy"
        rm -f ~/sync/bin/$main
        cp dist/$main ~/sync/bin/
    else
        echo "FAILED to build $main"
    fi
}

do_install rephile
do_install herbie
do_install barpyrus multiprocessing
do_install titome 
