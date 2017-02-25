FROM node

WORKDIR /usr/src/app

RUN set -ex; \
    apt-get update -qq; \
    apt-get install -qy apt-transport-https ca-certificates; \
    curl -fsS https://dl.yarnpkg.com/debian/pubkey.gpg > yarn-pubkey.gpg; \
    apt-key add yarn-pubkey.gpg; \
    rm yarn-pubkey.gpg; \
    echo 'deb https://dl.yarnpkg.com/debian/ stable main' > /etc/apt/sources.list.d/yarn.list; \
    apt-get update -qq; \
    apt-get install -qy yarn

ARG NODE_ENV
ENV NODE_ENV $NODE_ENV

COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

COPY elm-package.json ./
RUN ./node_modules/.bin/elm-package install --yes

COPY src src
RUN ./node_modules/.bin/elm-make --output=build/presentations/99-problems.js src/presentations/99-problems.elm

COPY database.yaml ./

CMD ["./src/main.js"]
