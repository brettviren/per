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

do_install () {
    main=$1 ; shift
    
    if [ -f $main/requirements.txt ] ; then
        cd $main
        pip install -r requirements.txt
        cd -
    fi

    args="--onefile -n $main"
    for mod in $@
    do
        args="$args --hidden-import $mod"
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
    pyinstaller $args $mainsrc

    if [ -f dist/$main ] ; then
        cp dist/$main ~/sync/bin/
    else
        echo "FAILED to build $main"
    fi
}

do_install rephile
do_install herbie
do_install barpyrus multiprocessing

