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

const env = (name, defaultValue) => {
  const value = process.env[name] || defaultValue
  if (!value) {
    throw new Error(`Required environment variable: ${name}`)
  }
  return value
}

const port = parseInt(env('PORT'), 10)
const environment = env('NODE_ENV', 'development')
const inProduction = environment === 'production'

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
  data.talks = parseDates(data.talks)
  data.workshops = parseDates(data.workshops)

  const today = moment().startOf('day')
  data.upcomingTalks = data.talks
    .filter(event => event.date.isAfter(today))
  data.upcomingWorkshops = data.workshops
    .filter(event => event.date.isAfter(today))

  return data
}

const parseDates = events =>
  (events || [])
    .map(event =>
      Object.assign({}, event, {date: moment(event.date)}))
    .map(event =>
      Object.assign({}, event, {
        isoDate: event.date.format('YYYY-MM-DD'),
        formattedDate: event.date.format('dddd Do MMMM, YYYY')
      }))

const page = viewFile => function*(data) {
  return pug.renderFile(`src/views/${viewFile}`, Object.assign({}, data, {pretty: true, cache: inProduction}))
}

const app = koa.app()
app.use(koa.route.get('/', function*() {
  const data = yield loadDatabase()
  this.type = 'text/html'
  this.body = yield page('home.pug')(data)
}))
app.use(koa.route.get('/events/:slug/:date', function*(slug, date) {
  const data = yield loadDatabase()
  const event = data.workshops.concat(data.talks).find(event => event.slug === slug && event.isoDate === date)
  if (!event) {
    this.throw(404)
  }

  this.type = 'text/html'
  this.body = yield page(`events/${slug}.pug`)(event)
}))
app.use(koa.route.get('/site.css', function*() {
  this.type = 'text/css'
  this.body = (yield renderSass({file: 'src/site.scss'})).css
}))

app.listen(port)
console.log(JSON.stringify({
  message: 'Application started.',
  port: port,
  environment: environment
}))
