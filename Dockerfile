FROM node

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

ARG NODE_ENV
ENV NODE_ENV $NODE_ENV

COPY package.json .
RUN npm install

COPY build build
COPY src src
COPY database.yaml .

CMD ["npm", "--silent", "start"]
