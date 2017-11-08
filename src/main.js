#!/usr/bin/env node

const server = require('./server')

const env = (name, defaultValue) => {
  const value = process.env[name] || defaultValue
  if (!value) {
    throw new Error(`Required environment variable: ${name}`)
  }
  return value
}

server
  .start({
    environment: env('NODE_ENV', 'development'),
    port: parseInt(env('PORT'), 10),
    log: console.log, // eslint-disable-line no-console
  })
  .then(appServer => {
    process.once('SIGINT', appServer.stop)
    process.once('SIGTERM', appServer.stop)
    process.once('SIGUSR2', () =>
      appServer.stop().then(() => process.kill(process.pid, 'SIGUSR2')),
    )
  })
  .catch(error => {
    // eslint-disable-next-line no-console
    console.error(error)
    process.exit(1)
  })
