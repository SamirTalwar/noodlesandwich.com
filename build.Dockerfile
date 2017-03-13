FROM node

RUN set -ex; \
    apt-get -qq update; \
    apt-get -qy install apt-transport-https ca-certificates curl software-properties-common

RUN set -ex; \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -; \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian `lsb_release -cs` stable"; \
    apt-get -qq update; \
    apt-get -qy install docker-ce
