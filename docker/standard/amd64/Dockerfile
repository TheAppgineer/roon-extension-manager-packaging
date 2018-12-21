# Use an official node runtime as a parent image
FROM node:8.10.0-alpine

RUN apk update && apk upgrade && \
    apk add --no-cache bash git openssh tzdata wget

WORKDIR /root
RUN wget https://raw.githubusercontent.com/TheAppgineer/roon-extension-manager-packaging/master/linux/setup.sh
RUN chmod +x setup.sh && SVC=0 ./setup.sh
VOLUME /root/.RoonExtensions/lib

WORKDIR /root/.RoonExtensions/lib
CMD [ "./roon-extension-manager.sh" ]
