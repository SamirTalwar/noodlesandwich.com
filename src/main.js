#!/usr/bin/env node

const server = require('./server')

server.start()
  .then(appServer => {
    process.on('SIGINT', appServer.stop)
    process.on('SIGTERM', appServer.stop)
  })
