#Build image
FROM ubuntu:18.04 as build-stage

RUN apt-get -y update
RUN apt-get -y install wget build-essential gcc g++ automake git-core autoconf make patch libmysql++-dev mysql-server libtool libssl-dev grep binutils zlibc libc6 libbz2-dev cmake subversion libboost-all-dev

WORKDIR /cmake
RUN wget --no-check-certificate https://github.com/Kitware/CMake/releases/download/v3.16.5/cmake-3.16.5.tar.gz
RUN tar -zxvf cmake-3.16.5.tar.gz
WORKDIR /cmake/cmake-3.16.5
RUN ./bootstrap
RUN make -j4
RUN make install

COPY . /src
WORKDIR /src/build

#Install mangos
RUN cmake .. -DCMAKE_INSTALL_PREFIX=/mangos -DBUILD_GAME_SERVER=0 -DBUILD_LOGIN_SERVER=1
RUN make -j4
RUN make install

#Runtime image
FROM ubuntu:18.04 as runtime

RUN apt-get -y update && apt-get -y upgrade
RUN apt-get -y install libmysqlclient20 openssl mysql-client

COPY --from=build-stage /mangos /mangos
WORKDIR /mangos/bin
RUN chmod +x realmd
COPY --from=build-stage /src/docker/realmd/entrypoint.sh /entrypoint.sh

#Copy config files to tmp directory
WORKDIR /mangos/tmp/
RUN cp ../etc/realmd.conf.dist realmd.conf

EXPOSE 3724
ENTRYPOINT [ "/bin/bash", "/entrypoint.sh"]
