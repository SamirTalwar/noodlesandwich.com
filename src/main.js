#!/usr/bin/env node

const server = require('./server')

const env = (name, defaultValue) => {
  const value = process.env[name] || defaultValue
  if (!value) {
    throw new Error(`Required environment variable: ${name}`)
  }
  return value
}

const port = parseInt(env('PORT'), 10)
const environment = env('NODE_ENV', 'development')

server.start({port, environment})
  .then(appServer => {
    process.on('SIGINT', appServer.stop)
    process.on('SIGTERM', appServer.stop)
  })
