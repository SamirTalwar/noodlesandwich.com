#!/usr/bin/env node

const fs = require('fs')
const koa = {
  app: require('koa'),
  route: require('koa-route')
}
const pug = require('pug')

const env = name => {
  const value = process.env[name]
  if (!value) {
    throw new Error(`Required environment variable: ${name}`)
  }
  return value
}

const port = parseInt(env('PORT'), 10)

const readFile = function (...args) {
  return new Promise((resolve, reject) => {
    fs.readFile(...args, (error, data) => {
      if (error) {
        reject(error)
      } else {
        resolve(data)
      }
    })
  })
}

const pages = {
  home: function*() {
    const template = yield readFile('views/home.pug')
    return pug.compile(template)()
  }
}

const app = koa.app()
app.use(koa.route.get('/', function*() {
  this.body = yield pages.home()
}))

app.listen(port)
console.log(JSON.stringify({
  message: 'Application started.',
  port: port
}))
