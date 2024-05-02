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
  wget https://github.com/jkbonfield/io_lib/releases/download/io_lib-1-15-0/io_lib-1.15.0.tar.gz
  echo -n "Building io_lib cram-filter...1.15.0"
  tar -xvf io_lib-1.15.0.tar.gz 
  cd $TMPDIR/downloads/io_lib-1.15.0 
  ./bootstrap
  ./configure --prefix=$OPT 
  make -s
  make install

  rm -rf /tmp/hts_cache
  rm -rf $TMPDIR/downloads
