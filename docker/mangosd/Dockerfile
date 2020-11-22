#download extraction data
FROM alpine:latest as data-step
WORKDIR /data
RUN wget https://km-branch.s3-us-west-2.amazonaws.com/1.12.1-extracted-client-data.tar.gz -O data.tar.gz
RUN tar -xf data.tar.gz 2>&1

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
RUN cmake .. -DCMAKE_INSTALL_PREFIX=/mangos -DBUILD_GAME_SERVER=1 -DBUILD_LOGIN_SERVER=0 -DBUILD_PLAYERBOT=ON -DBUILD_AHBOT=ON
RUN make -j4
RUN make install

FROM alpine:latest as db-step
RUN apk update && apk add git
RUN git clone https://github.com/cmangos/classic-db

#Runtime image
FROM ubuntu:18.04 as runtime

RUN apt-get -y update && apt-get -y upgrade
RUN apt-get -y install libmysqlclient20 openssl mysql-client

COPY --from=build-stage /mangos /mangos
WORKDIR /mangos/bin
RUN chmod +x mangosd
COPY --from=build-stage /src/docker/mangosd/entrypoint.sh /entrypoint.sh

#Copy config files to final image tmp directory
RUN mkdir /mangos/tmp/
WORKDIR /mangos/etc/
RUN for f in *.dist; do cp "$f" ../tmp/"${f%%.conf.dist}.conf"; done

#Copy sql files for initialization
COPY --from=build-stage /src/sql /mangos/sql

#Copy acquired extraction data to runtime image
COPY --from=data-step /data /mangos/bin

#Copy initialization sql scripts to runtime image
COPY --from=db-step /classic-db /mangos/db

EXPOSE 8085
ENTRYPOINT [ "/bin/bash", "/entrypoint.sh" ]
