#!/bin/bash

echo "FROM buildpack-deps:$(awk -F'_' '{print tolower($2)}' <<< $LINUX_VERSION)"

echo "RUN apt-get update"

if [ $VALGRIND = "true" ] ; then
    echo "RUN apt-get install -y valgrind && valgrind --version"
fi

if [ $CLANG = "true" ] ; then
    echo "RUN apt-get install -y clang-8 && \
    ln -s /usr/bin/clang-8 /usr/bin/clang && \
    ln -s /usr/bin/clang++-8 /usr/bin/clang++ && \
    clang -v && \
    clang++ -v"
fi

if [ $GCC = "true" ] ; then
    echo "RUN gcc -v && \
    g++ -v"
fi

if [ ! -e $CMAKE_VERSION_NUM ] ; then
    CMAKE_STR="$(awk -F'.' '{ print $1"."$2"."$3 }' <<< ${CMAKE_VERSION_NUM}.0)"
    echo "RUN wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_STR}/cmake-${CMAKE_STR}-Linux-x86_64.tar.gz && \
    tar -xzvf cmake-${CMAKE_STR}-Linux-x86_64.tar.gz &&\
    cp -r cmake-${CMAKE_STR}-Linux-x86_64/share/* /usr/share/ &&\
    cp -r cmake-${CMAKE_STR}-Linux-x86_64/bin/* /usr/bin/ &&\
    cmake --version"
fi

if [ ! -e $GTEST_VERSION_NUM ] ; then
    GTEST_STR="$(awk -F'.' '{ print $1"."$2"."$3 }' <<< ${GTEST_VERSION_NUM}.0)"
    echo "RUN wget https://github.com/google/googletest/archive/release-${GTEST_STR}.tar.gz && \
    tar -xzvf release-${GTEST_STR}.tar.gz && \
    cd googletest-release-${GTEST_STR} && \
    mkdir build && \
    cd build && \
    cmake ../ && \
    make -j6 gtest && \
    make install && \
    pkg-config gtest --modversion"
fi

if [ ! -e $RUBY_VERSION_NUM ] ; then
    echo "RUN apt-get install -y libssl-dev && wget http://ftp.ruby-lang.org/pub/ruby/$(awk -F'.' '{ print $1"."$2 }' <<< $RUBY_VERSION_NUM)/ruby-$RUBY_VERSION_NUM.tar.gz && \
    tar -xzvf ruby-$RUBY_VERSION_NUM.tar.gz && \
    cd ruby-$RUBY_VERSION_NUM/ && \
    ./configure && \
    make -j4 && \
    make install && \
    ruby -v"
fi

if [ ! -e $NODE_VERSION_NUM ] ; then
    echo "RUN wget https://nodejs.org/dist/v$NODE_VERSION_NUM/node-v$NODE_VERSION_NUM.tar.gz && \
    tar -xzvf node-v$NODE_VERSION_NUM.tar.gz && \
    rm node-v$NODE_VERSION_NUM.tar.gz && \
    cd node-v$NODE_VERSION_NUM && \
    ./configure && \
    make -j4 && \
    make install && \
    cd .. && \
    rm -r node-v$NODE_VERSION_NUM"
fi

if [ ! -e $PYTHON_VERSION_NUM ] ; then
    echo "RUN wget https://www.python.org/ftp/python/$PYTHON_VERSION_NUM/Python-$PYTHON_VERSION_NUM.tgz && \
    tar xzf Python-$PYTHON_VERSION_NUM.tgz && \
    rm Python-$PYTHON_VERSION_NUM.tgz && \
    cd Python-$PYTHON_VERSION_NUM && \
    ./configure && \
    make install"
fi

if [ $NETCDF = "true" ] || [ $HDF5 = "true" ]; then
    echo "RUN wget https://www.hdfgroup.org/package/hdf5-1-10-5-tar-bz2/?wpdmdl=13570 -O hdf5-1.10.5.tar.bz2 && \
    tar -xjvf hdf5-1.10.5.tar.bz2 && \
    cd hdf5-1.10.5 && \
    ./configure --prefix=/usr/local --enable-using-memchecker --enable-build-mode=production --enable-optimization=high && \
    make -j6 && \
    make install && \
    cd / && ld -tl hdf5"
fi

if [ $NETCDF = "true" ]; then
    echo "RUN wget https://www.unidata.ucar.edu/downloads/netcdf/ftp/netcdf-c-4.7.0.tar.gz && \
    tar -xzvf netcdf-c-4.7.0.tar.gz && \
    cd netcdf-c-4.7.0 && \
    ./configure --prefix=/usr/local && \
    make -j6 && \
    make install && \
    nc-config --version"
fi

# if [ ! -e $PHP_VERSION_NUM ] ; then
#     wget "http://php.net/distributions/php-${PHP_VERSION_NUM}.tar.xz"
# fi

if [ $JAVA = "true" ] ; then
cat << EOF
RUN if [ \$(grep 'VERSION_ID="8"' /etc/os-release) ] ; then \\
    echo "deb http://ftp.debian.org/debian jessie-backports main" >> /etc/apt/sources.list && \\
    apt-get update && apt-get -y install -t jessie-backports openjdk-8-jdk ca-certificates-java \\
; elif [ \$(grep 'VERSION_ID="9"' /etc/os-release) ] ; then \\
		apt-get update && apt-get -y -q --no-install-recommends install -t stable openjdk-8-jdk ca-certificates-java \\
; elif [ \$(grep 'VERSION_ID="14.04"' /etc/os-release) ] ; then \\
		apt-get update && \\
    apt-get --force-yes -y install software-properties-common python-software-properties && \\
    echo | add-apt-repository -y ppa:webupd8team/java && \\
    apt-get update && \\
    echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \\
    echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections && \\
    apt-get -y install oracle-java8-installer \\
; elif [ \$(grep 'VERSION_ID="16.04"' /etc/os-release) ] ; then \\
    apt-get update && \\
    apt-get --force-yes -y install software-properties-common python-software-properties && \\
    echo | add-apt-repository -y ppa:webupd8team/java && \\
    apt-get update && \\
    echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \\
    echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections && \\
    apt-get -y install oracle-java8-installer \\
; fi
EOF
fi

if [ $MYSQL_CLIENT = "true" ] ; then
    echo "RUN apt-get -y install mysql-client"
fi

if [ $POSTGRES_CLIENT = "true" ] ; then
    echo "RUN apt-get -y install postgresql-client"
fi

if [ $DOCKERIZE = "true" ] ; then
DOCKERIZE_VERSION="v0.6.1"

cat << EOF
RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz && \\
    tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz && \\
    rm dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz
EOF
fi

# install bats for testing
echo "RUN git clone https://github.com/sstephenson/bats.git \
  && cd bats \
  && ./install.sh /usr/local \
  && cd .. \
  && rm -rf bats"

# install dependencies for tap-to-junit
echo "RUN perl -MCPAN -e 'install TAP::Parser'"
echo "RUN perl -MCPAN -e 'install XML::Generator'"

# install lsb-release, etc., for testing linux distro
echo "RUN apt-get update && apt-get -y install lsb-release unzip"

if [ $BROWSERS = "true" ] ; then
cat << EOF
RUN if [ \$(grep 'VERSION_ID="8"' /etc/os-release) ] ; then \\
    echo "deb http://ftp.debian.org/debian jessie-backports main" >> /etc/apt/sources.list && \\
    apt-get update && apt-get -y install -t jessie-backports xvfb phantomjs \\
; else \\
		apt-get update && apt-get -y install xvfb phantomjs \\
; fi
EOF
echo "ENV DISPLAY :99"

echo "# install firefox
RUN curl --silent --show-error --location --fail --retry 3 --output /tmp/firefox.deb https://s3.amazonaws.com/circle-downloads/firefox-mozilla-build_47.0.1-0ubuntu1_amd64.deb \
  && echo 'ef016febe5ec4eaf7d455a34579834bcde7703cb0818c80044f4d148df8473bb  /tmp/firefox.deb' | sha256sum -c \
  && dpkg -i /tmp/firefox.deb || apt-get -f install  \
  && apt-get install -y libgtk3.0-cil-dev libasound2 libasound2 libdbus-glib-1-2 libdbus-1-3 \
  && rm -rf /tmp/firefox.deb"

echo "# install chrome
RUN curl --silent --show-error --location --fail --retry 3 --output /tmp/google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
  && (dpkg -i /tmp/google-chrome-stable_current_amd64.deb || apt-get -fy install)  \
  && rm -rf /tmp/google-chrome-stable_current_amd64.deb \
  && sed -i 's|HERE/chrome\"|HERE/chrome\" --disable-setuid-sandbox --no-sandbox|g' \
       \"/opt/google/chrome/google-chrome\""

echo "# install chromedriver
RUN apt-get -y install libgconf-2-4 \
  && curl --silent --show-error --location --fail --retry 3 --output /tmp/chromedriver_linux64.zip \"http://chromedriver.storage.googleapis.com/2.33/chromedriver_linux64.zip\" \
  && cd /tmp \
  && unzip chromedriver_linux64.zip \
  && rm -rf chromedriver_linux64.zip \
  && mv chromedriver /usr/local/bin/chromedriver \
  && chmod +x /usr/local/bin/chromedriver"
fi
