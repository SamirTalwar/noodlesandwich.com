FROM node

WORKDIR /usr/src/app

COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

COPY src src
COPY database.yaml ./

CMD ["./src/main.js"]
