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

const main = () => {
  const port = parseInt(env('PORT'), 10)
  const environment = env('NODE_ENV', 'development')
  const inProduction = environment === 'production'

  const app = koa.app()
  app.use(function *(next) {
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
  })
  app.use(function *(next) {
    this.set('Content-Security-Policy', 'default-src * \'unsafe-inline\'')
    this.set('X-Frame-Options', 'DENY')
    this.set('X-XSS-Protection', '1; mode=block')
    yield next
  })
  app.use(koa.route.get('/', function*() {
    const data = yield cached('database', inProduction, loadDatabase)
    this.type = 'text/html'
    this.body = yield cached('home.pug', inProduction, page('home.pug'))(data)
  }))
  app.use(koa.route.get('/events/:slug/:date', function*(slug, date) {
    const data = yield cached('database', inProduction, loadDatabase)
    const event = data.workshops.concat(data.talks).find(event => event.slug === slug && event.isoDate === date)
    if (!event) {
      this.throw(404)
    }

    this.type = 'text/html'
    this.body = yield cached(`events/${slug}.pug`, inProduction, page(`events/${slug}.pug`))(event)
  }))
  app.use(koa.route.get('/site.css', function*() {
    this.type = 'text/css'
    this.body = (yield cached('site.scss', inProduction, renderSass)({file: 'src/site.scss'})).css
  }))

  app.listen(port)
  console.log(JSON.stringify({
    message: 'Application started.',
    port: port,
    environment: environment
  }))
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

const cache = new Map()
const cached = (description, when, behaviour) => function*(...args) {
  if (!when) {
    return yield behaviour.apply(this, args)
  }

  const key = {description: description, arguments: args}
  const keyString = JSON.stringify(key)
  let value = cache.get(keyString)
  if (value == null) {
    console.log(JSON.stringify({
      cacheMiss: key
    }))
    value = yield behaviour.apply(this, args)
    cache.set(keyString, value)
  }
  return value
}

main()
