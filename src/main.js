#!/usr/bin/env node

const server = require('./server')

const appServer = server.start()
process.on('SIGINT', appServer.stop)
process.on('SIGTERM', appServer.stop)
