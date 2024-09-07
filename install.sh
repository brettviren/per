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

# install promnesia purely via pip, no source.
do_install_promnesia () {
    pybin=$(dirname $(which python))

    pip install promnesia orgparse mistletoe python-magic bs4 HPI cashew logzero orjson mypy git+https://github.com/karlicoss/rexport
    pyinstaller --onefile --hidden-import orgparse --hidden-import mistletoe --hidden-import python-magic --hidden-import bs4 --hidden-import HPI --hidden-import cashew --hidden-import logzero --hidden-import orgjson --hidden-import mypy --hidden-import rexport  -n promnesia $pybin/promnesia
    rm -f ~/sync/bin/promnesia
    cp dist/promnesia ~/sync/bin/
}

do_install rephile
do_install herbie
do_install barpyrus multiprocessing
do_install titome 
do_install_promnesia

