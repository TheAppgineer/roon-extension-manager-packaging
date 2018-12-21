# Use an official node runtime as a parent image
FROM amd64/node:8.14.1-alpine

RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
        bash \
        git \
        tzdata \
        wget

WORKDIR /root
RUN wget https://raw.githubusercontent.com/TheAppgineer/roon-extension-manager-packaging/master/linux/setup.sh && \
    chmod +x setup.sh && \
    SVC=0 ./setup.sh
VOLUME /root/.RoonExtensions/lib

WORKDIR /root/.RoonExtensions/lib
CMD [ "./roon-extension-manager.sh" ]
