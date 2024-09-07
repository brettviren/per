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

get_logd () {
    main=$1; shift
    l=$perdir/logs/$main
    if [ ! -d $l ] ; then
        mkdir -p $l
    fi
    echo $l
}
    

do_pyinstaller () {
    main=$1 ; shift
    logd=$(get_logd $main)

    args="--onefile -n $main"
    for mod in $@
    do
        args="$args --hidden-imports $mod"
    done

    pybin=$(dirname $(which python))

    mainsrc=""
    if [ -f $main/$main/__main__.py ] ; then
        mainsrc="$main/$main/__main__.py"
    elif [ -f $main/${main}.py ] ; then
        mainsrc="$main/${main}.py"
    elif [ -f $pybin/${main} ] ; then
        mainsrc="$pybin/$main"
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


do_install () {
    main=$1 ; shift
    echo "installing $main" 
    
    logd=$(get_logd $main)

    # rm -rf build dist ${main}.spec

    if [ -f $main/requirements.txt ] ; then
        cd $main
        pip install -r requirements.txt > $logd/pip-install.log 2>&1
        cd ..
    fi

    do_pyinstaller $main $@
}

# install promnesia purely via pip, no source.
do_install_promnesia () {
    pip install promnesia orgparse mistletoe python-magic bs4 HPI cashew logzero orjson mypy git+https://github.com/karlicoss/rexport
    do_pyinstaller promnesia orgparse mistletoe python-magic bs4 HPI cashew logzero orgjson mypy rexport
}

do_install_wormhole () {
    pip install magic-wormhole
    do_pyinstaller wormhole
}

# do_install rephile
# do_install herbie
# do_install barpyrus multiprocessing
# do_install titome 
# do_install_promnesia
do_install_wormhole
