#!/bin/bash
set -v

# Install the dev dependencies for building Qpid proton system library.
sudo apt-get install -y gcc cmake cmake-curses-gui uuid-dev
sudo apt-get install -y libssl-dev
sudo apt-get install -y libsasl2-2 libsasl2-dev

# Get the latest Qpid Proton source
cd $HOME/build
git clone --branch 0.30.0 https://github.com/apache/qpid-proton.git
cd qpid-proton

# Configure the source of Qpid Proton.
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_BINDINGS=

# Compile system libraries.
make all

# Install system libraries
sudo make install

cd $TRAVIS_BUILD_DIR
set +v
