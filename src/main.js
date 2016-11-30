#!/usr/bin/env node

require('sqreen')

const server = require('./server')

const env = (name, defaultValue) => {
  const value = process.env[name] || defaultValue
  if (!value) {
    throw new Error(`Required environment variable: ${name}`)
  }
  return value
}

server.start({
  environment: env('NODE_ENV', 'development'),
  port: parseInt(env('PORT'), 10),
  log: console.log
})
  .then(appServer => {
    process.once('SIGINT', appServer.stop)
    process.once('SIGTERM', appServer.stop)
    process.once('SIGUSR2', appServer.stop)
  })
