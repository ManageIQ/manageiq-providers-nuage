#!/bin/bash

# Ensure correct Ruby environment is used.
. ~/.rvm/scripts/rvm
rvm use $TRAVIS_RUBY_VERSION

# We have to extract the major and minor ruby versions so that we can set proper GEM_HOME
ruby_version=`echo $TRAVIS_RUBY_VERSION | egrep -o '[[:digit:]]\.[[:digit:]]'`

# As we are installing the Gem built from source, we have to set the proper
# GEM_HOME. This will ensure that the gem will be installed in a place where it
# will be picked by bundler.
export GEM_HOME=/home/travis/build/ManageIQ/manageiq-providers-nuage/vendor/bundle/ruby/$ruby_version.0

# Install the dev dependencies for building Qpid proton system library.
sudo apt-get install -y gcc cmake cmake-curses-gui uuid-dev
sudo apt-get install -y libssl-dev
sudo apt-get install -y libsasl2-2 libsasl2-dev
sudo apt-get install -y swig

# Get the latest Qpid Proton source
cd $HOME/build
git clone https://github.com/apache/qpid-proton.git
cd qpid-proton

# There is a strange dependency on JSON that we need to change to version of
# at least 2; otherwise there will be a conflict.
sed -i .bak -e 's/ 0/ 2/' proton-c/bindings/ruby/qpid_proton.gemspec.in

# Configure the source of Qpid Proton.
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$HOME/pkg -DSYSINSTALL_BINDINGS=OFF

# Make system libraries and the gem.
make all

# Install system libraries
make install

# Manually install the Ruby Gem. This will be installed inside $GEM_HOME directory.
gem install proton-c/bindings/ruby/qpid_proton-0.18.0.gem -- --with-qpid-proton-lib=$HOME/pkg/lib --with-qpid-proton-include=$HOME/pkg/include/
