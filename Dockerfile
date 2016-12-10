FROM node

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

ARG NODE_ENV
ENV NODE_ENV $NODE_ENV

COPY package.json .
RUN npm --silent install

COPY elm-package.json .
RUN ./node_modules/.bin/elm-package install --yes

COPY src src
RUN ./node_modules/.bin/elm-make --output=build/presentations/99-problems.js src/presentations/99-problems.elm

COPY database.yaml .

CMD ["npm", "--silent", "start"]
