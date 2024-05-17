#!/bin/bash

set -xe

if [[ -z "${TMPDIR}" ]]; then
	  TMPDIR=/tmp
  fi

  set -u

  rm -rf $TMPDIR/downloads

  mkdir -p $TMPDIR/downloads $OPT/bin $OPT/etc $OPT/lib $OPT/share $OPT/site /tmp/hts_cache

  # io_lib to run the carm_filter
  cd $TMPDIR/downloads
  #wget https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
  curl -L -o install-tl-unx.tar.gz https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
  tar -xvf install-tl-unx.tar.gz
  cd install-tl-2*
  perl ./install-tl --no-interaction -scheme basic
  cd $TMPDIR/downloads
  wget https://github.com/jkbonfield/io_lib/releases/download/io_lib-1-15-0/io_lib-1.15.0.tar.gz
  echo -n "Building io_lib cram-filter...1.15.0"
  tar -xvf io_lib-1.15.0.tar.gz 
  cd $TMPDIR/downloads/io_lib-1.15.0 
  ./bootstrap
  ./configure --prefix=$OPT 
  make -s
  make install
  
  pip3 install https://github.com/cancerit/ta_analyser/releases/download/1.1.0/analyse_ta-1.1.0-py3-none-any.whl

  rm -rf /tmp/hts_cache
  rm -rf $TMPDIR/downloads
