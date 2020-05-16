# Use an official node runtime as a parent image
FROM node:12.16.3-alpine

WORKDIR /root

COPY setup.sh roon-extension-manager.sh ./

RUN apk add --no-cache \
        bash \
        git \
        tzdata && \
    SVC=0 ./setup.sh && \
    rm setup.sh

COPY docker/features.json .RoonExtensions/etc/

VOLUME /root/.RoonExtensions/lib

WORKDIR /root/.RoonExtensions/lib
CMD [ "../bin/roon-extension-manager.sh", "/root/.RoonExtensions/etc/features.json" ]
