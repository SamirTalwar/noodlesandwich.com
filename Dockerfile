FROM node

WORKDIR /usr/src/app

COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

COPY build build
COPY src src
COPY database.yaml ./

CMD ["./src/main.js"]
