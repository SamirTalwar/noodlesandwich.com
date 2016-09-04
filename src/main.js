#!/usr/bin/env node

const fs = require('fs')
const koa = {
  app: require('koa'),
  route: require('koa-route')
}
const pug = require('pug')
const sass = require('node-sass')

const env = name => {
  const value = process.env[name]
  if (!value) {
    throw new Error(`Required environment variable: ${name}`)
  }
  return value
}

const port = parseInt(env('PORT'), 10)

const denodeify = func => (...args) =>
  new Promise((resolve, reject) => {
    func(...args, (error, value) => {
      if (error) {
        reject(error)
      } else {
        resolve(value)
      }
    })
  })

const readFile = denodeify(fs.readFile)
const renderSass = denodeify(sass.render)

const pages = {
  home: function*() {
    const template = yield readFile('views/home.pug')
    return pug.compile(template, {filename: 'views/home.pug', pretty: true})()
  }
}

const app = koa.app()
app.use(koa.route.get('/', function*() {
  this.type = 'text/html'
  this.body = yield pages.home()
}))
app.use(koa.route.get('/site.css', function*() {
  this.type = 'text/css'
  this.body = (yield renderSass({file: 'src/site.scss'})).css
}))

app.listen(port)
console.log(JSON.stringify({
  message: 'Application started.',
  port: port
}))
