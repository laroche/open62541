#!/bin/bash

if test "X$1" = Xinstall ; then
  if grep -q Debian /etc/os-release ; then
    sudo apt-get install git cmake make libmbedtls-dev python3-sphinx texlive-base python3-pkgconfig check libpcap-dev libreadline-dev clang-19 # libssl-dev cmake-qt-gui arm-none-eabi-gcc
  else
    sudo apt-get install git cmake make libmbedtls-dev python3-sphinx texlive-base python3-pkgconfig check libpcap-dev libreadline-dev # libssl-dev cmake-qt-gui arm-none-eabi-gcc
  fi
  exit 0
fi

if test "X$1" = Xupload ; then
  rsync -av --delete --exclude=build . debian-14:data/open62541/
  exit 0
fi

# Checkout the source the first time:
if ! test -d open62541-1.5 ; then
  #git clone https://github.com/open62541/open62541
  git clone -b 1.5 https://github.com/open62541/open62541 open62541-1.5
  pushd open62541-1.5
    git config pull.rebase false
    patch -s -p1 < ../open62541-1.5.patch
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
  pushd open62541-1.5
    git diff --ignore-submodules=dirty > ../open62541-1.5.patch2
    pushd deps/mdnsd
      git diff > ../../../open62541-mdnsd.patch2
    popd
  popd
  diff -u open62541-1.5.patch open62541-1.5.patch2
  diff -u open62541-mdnsd.patch open62541-mdnsd.patch2
  mv open62541-1.5.patch2 open62541-1.5.patch
  mv open62541-mdnsd.patch2 open62541-mdnsd.patch
  exit 0
fi

# Update the source:
if test "X$1" = Xupdate ; then
  pushd open62541-1.5
    git stash
    git pull -a --all
    git stash pop
    # XXX No update to mdns, we stay at normal checkout:
    #git submodule update --remote
  popd
  exit 0
fi

if test "X$USE_CLANG" = X1 ; then
  if grep -q 22.04 /etc/os-release ; then
    export CC=clang-15
    export CXX=clang++-15
    SB="scan-build-15 --use-cc=$CC --use-c++=$CXX"
    SBM="$SB --status-bugs" # --exclude=../src/util --exclude=../tests"
  else
    export CC=clang-19
    export CXX=clang++-19
    SB="scan-build-19 --use-cc=$CC --use-c++=$CXX"
    SBM="$SB --status-bugs" # --exclude=../src/util --exclude=../tests"
  fi
fi
pushd open62541-1.5
  sudo rm -fr build
  mkdir -p build
  pushd build
    if test "X$1" = Xfreertos-lwip ; then
      $SB cmake .. -DUA_ARCHITECTURE=freertos-lwip
    else
      $SB cmake ..
    fi
    make clean
    if test -n "$SB"; then
      $SBM make
    else
      $SBM make -j 12
    fi
    #cmake --build . --verbose --parallel
    if test "X$1" = Xtest ; then
      #sudo ETHERNET_INTERFACE=eno1 make test
      sudo make test
    fi
  popd
popd
