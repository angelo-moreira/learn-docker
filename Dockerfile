# docker build -t elixir-docker-guide .
# docker container run -i elixir-docker-guide
# docker exec -it docker-guide-container sh

#===========
#Build Stage
#===========
FROM elixir:1.5-alpine as build
LABEL maintainer="Angelo Moreira <angelo.m@designone.co.uk>"

ENV VERSION=0.1


# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

#Copy the source folder into the Docker image
COPY . .

#Install dependencies and build Release
RUN export MIX_ENV=prod && \
    rm -Rf _build && \
    mix deps.get && \
    mix release

#Extract Release archive to /rel for copying in next stage
# I think we need to substitute "clock" with a APP_NAME env to make it general for multiple projects
RUN APP_NAME="clock" && \ 
    RELEASE_DIR=`ls -d _build/prod/rel/$APP_NAME/releases/*/` && \
    mkdir /export && \
    tar -xf "$RELEASE_DIR/$APP_NAME.tar.gz" -C /export


#================
#Deployment Stage
#================
FROM alpine:3.6

#Install Dependencies for Erlang
RUN apk add --no-cache \
    ncurses-libs \
    zlib \
    openssl \
    ca-certificates && \
    update-ca-certificates --fresh

#Install bash which is required by Distillery
RUN apk add --no-cache bash

ENV HOME=/opt/app

#Create /opt/app directory and default user
RUN mkdir -p ${HOME} && \
    adduser -s /bin/sh -u 1001 -G root -h ${HOME} -S -D default && \
    chown -R 1001:0 ${HOME} && \
    apk --no-cache upgrade

WORKDIR ${HOME}

EXPOSE 4000
ENV REPLACE_OS_VARS=true \
    PORT=4000

#Copy and extract .tar.gz Release file from the previous stage
COPY --from=build /export/ .

#Change user
USER default

#Set default entrypoint and command
# ENTRYPOINT ["/opt/app/bin/clock"]
# CMD ["foreground"]