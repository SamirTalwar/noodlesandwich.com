#!/usr/bin/env node

const fs = require('fs')
const koa = {
  app: require('koa'),
  route: require('koa-route')
}
const moment = require('moment')
const pug = require('pug')
const sass = require('node-sass')
const yaml = require('js-yaml')

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

const loadDatabase = function*() {
  const data = yaml.safeLoad(yield readFile('database.yaml'))
  data.upcomingTalks = formatEvents(data.talks)
  data.upcomingWorkshops = formatEvents(data.workshops)
  return data
}

const formatEvents = events => {
  const today = moment().startOf('day')
  return events
    .map(event =>
      Object.assign({}, event, {
        date: moment(event.date),
        formattedDate: moment(event.date).format('dddd Do MMMM, YYYY')
      }))
    .filter(event => event.date.isAfter(today))
}

const pages = {
  home: function*(data) {
    const template = yield readFile('views/home.pug')
    return pug.compile(template, {filename: 'views/home.pug', pretty: true})(data)
  }
}

const app = koa.app()
app.use(koa.route.get('/', function*() {
  const data = yield loadDatabase()
  this.type = 'text/html'
  this.body = yield pages.home(data)
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
