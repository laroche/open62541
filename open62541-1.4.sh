#!/bin/bash

if test "X$1" = Xinstall ; then
  if grep -q Debian /etc/os-release ; then
    sudo apt-get install git cmake make libmbedtls-dev python3-sphinx texlive-base pkg-config python3-pkgconfig check # libssl-dev cmake-qt-gui arm-none-eabi-gcc
  else
    sudo apt-get install git cmake make libmbedtls-dev sphinx texlive-base pkgconfig check # libssl-dev cmake-qt-gui arm-none-eabi-gcc
  fi
  exit 0
fi
# Checkout the source the first time:
if ! test -d open62541-1.4 ; then
  #git clone https://github.com/open62541/open62541
  git clone -b 1.4 https://github.com/open62541/open62541 open62541-1.4
  pushd open62541-1.4
    git config pull.rebase false
    patch -s -p1 < ../open62541-1.4.patch
    #git submodule update --init --recursive
    #git submodule update --checkout --init --depth 1 FreeRTOS/Source 
    #git submodule update --checkout --init deps/nodesetLoader
    git submodule update --checkout --init deps/mdnsd
    #git submodule update --remote
    pushd deps/mdnsd
      git config pull.rebase false
      patch -s -p1 < ../../../open62541-mdnsd.patch
    popd
  popd
fi

# Create new patch file after editing further files:
if test "X$1" = Xpatch ; then
  pushd open62541-1.4
    git diff --ignore-submodules=dirty > ../open62541-1.4.patch2
    pushd deps/mdnsd
      git diff > ../../../open62541-mdnsd.patch2
    popd
  popd
  diff -u open62541-1.4.patch open62541-1.4.patch2
  diff -u open62541-mdnsd.patch open62541-mdnsd.patch2
  mv open62541-1.4.patch2 open62541-1.4.patch
  mv open62541-mdnsd.patch2 open62541-mdnsd.patch
  exit 0
fi

# Update the source:
if test "X$1" = Xupdate ; then
  pushd open62541-1.4
    git stash
    git pull -a --all
    git stash pop
    # XXX No update to mdns, we stay at normal checkout:
    #git submodule update --remote
  popd
  exit 0
fi

pushd open62541-1.4
  sudo rm -fr build
  mkdir -p build
  pushd build
    cmake ..
    make clean
    make -j 12
    #cmake --build . --verbose --parallel
    if test "X$1" = Xtest ; then
      sudo make test
    fi
  popd
popd
