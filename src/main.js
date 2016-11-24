#!/usr/bin/env node

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
    process.on('SIGINT', appServer.stop)
    process.on('SIGTERM', appServer.stop)
  })
