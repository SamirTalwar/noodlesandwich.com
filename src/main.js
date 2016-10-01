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

const Cache = require('./cache')

const main = () => {
  const port = parseInt(env('PORT'), 10)
  const environment = env('NODE_ENV', 'development')
  const inProduction = environment === 'production'

  const cached = Cache(inProduction)

  const app = koa.app()
  app.use(timeResponse)
  app.use(setSecurityHeaders)

  app.use(koa.route.get('/', function*() {
    const data = yield cached('database', loadDatabase)
    this.type = 'text/html'
    this.body = yield cached('home.pug', page('home.pug'))(data)
  }))

  app.use(koa.route.get('/events/:slug/:date', function*(slug, date) {
    const data = yield cached('database', loadDatabase)
    const event = data.workshops.concat(data.talks).find(event => event.slug === slug && event.isoDate === date)
    if (!event) {
      this.throw(404)
    }

    this.type = 'text/html'
    this.body = yield cached(`events/${slug}.pug`, page(`events/${slug}.pug`))(event)
  }))

  app.use(koa.route.get('/site.css', function*() {
    this.type = 'text/css'
    this.body = (yield cached('site.scss', renderSass)({file: 'src/site.scss'})).css
  }))

  const staticFile = (path, type) => {
    app.use(koa.route.get(`/${path}`, function*() {
      this.type = type
      this.body = yield readFile(`src/assets/${path}`)
    }))
  }

  staticFile('android-chrome-192x192.png', 'image/png')
  staticFile('android-chrome-512x512.png', 'image/png')
  staticFile('apple-touch-icon.png', 'image/png')
  staticFile('browserconfig.xml', 'application/xml')
  staticFile('favicon-16x16.png', 'image/png')
  staticFile('favicon-32x32.png', 'image/png')
  staticFile('favicon.ico', 'image/x-icon')
  staticFile('manifest.json', 'application/json')
  staticFile('mstile-150x150.png', 'image/png')
  staticFile('safari-pinned-tab.svg', 'image/svg+xml')

  app.listen(port)
  console.log(JSON.stringify({
    message: 'Application started.',
    port: port,
    environment: environment
  }))
}

const timeResponse = function *(next) {
  var start = new Date()
  yield next
  var responseTime = new Date() - start
  console.log(JSON.stringify({
    request: {
      method: this.method,
      url: this.url
    },
    response: {
      status: this.response.status,
      message: this.response.message,
      time: responseTime
    }
  }))
}

const setSecurityHeaders = function *(next) {
  this.set('Content-Security-Policy', 'default-src * \'unsafe-inline\'')
  this.set('X-Frame-Options', 'DENY')
  this.set('X-XSS-Protection', '1; mode=block')
  yield next
}

const loadDatabase = function*() {
  const database = yaml.safeLoad(yield readFile('database.yaml'))
  database.talks = parseDates(database.talks)
  database.workshops = parseDates(database.workshops)

  const today = moment().startOf('day')
  database.upcomingTalks = database.talks
    .filter(event => event.date.isSameOrAfter(today))
  database.upcomingWorkshops = database.workshops
    .filter(event => event.date.isSameOrAfter(today))

  return database
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
  return pug.renderFile(`src/views/${viewFile}`, Object.assign({}, data, {pretty: true}))
}

const env = (name, defaultValue) => {
  const value = process.env[name] || defaultValue
  if (!value) {
    throw new Error(`Required environment variable: ${name}`)
  }
  return value
}

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

main()
