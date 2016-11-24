const {decallbackify} = require('../src/promises')
const http = require('http')
const net = require('net')
const test = require('ava')

const server = require('../src/server')

test.beforeEach(t => {
  return availablePort()
    .then(port => {
      t.context.port = port
      return server.start({
        port,
        environment: 'test'
      })
    })
    .then(appServer => {
      t.context.appServer = appServer
    })
})

test.afterEach(t => {
  t.context.appServer.stop()
})

test('the home page renders well', t => {
  return get(`http://localhost:${t.context.port}/`)
    .then(response => {
      t.is(response.statusCode, 200)
      return pipeToString('utf8', response)
    })
    .then(body => {
      if (body.indexOf('<h1><a href="/">[≈]</a></h1>') < 0) {
        t.fail(`Could not find the site header in the body.\nBody:\n${body}`)
      }
    })
})

const availablePort = () => new Promise(resolve => {
  const potentialPort = randomNumberBetween(1024, 65536)
  const portChecker = net.createServer()
  portChecker.listen(potentialPort, () => {
    portChecker.once('close', () => resolve(potentialPort))
    portChecker.close()
  })
  portChecker.on('error', () => {
    availablePort().then(resolve)
  })
})

const randomNumberBetween = (low, high) =>
  Math.floor(Math.random() * (high - low) + low)

const get = decallbackify(http.get)

const pipeToString = (encoding, stream) => {
  return new Promise((resolve, reject) => {
    let string = ''
    stream.on('data', data => {
      string += data.toString(encoding)
    })
    stream.once('error', reject)
    stream.once('end', () => resolve(string))
  })
}
