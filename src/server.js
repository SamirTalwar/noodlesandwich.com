const fs = require('fs')
const koa = {
  app: require('koa'),
  route: require('koa-route')
}
const markdownIt = require('markdown-it')
const moment = require('moment')
const pug = require('pug')
const prism = require('prismjs')
const sass = require('node-sass')
const yaml = require('js-yaml')

const Cache = require('./cache')

const start = ({port, environment}) => {
  const inProduction = environment === 'production'

  const cached = Cache(inProduction)

  const app = koa.app()
  app.use(timeResponse)
  app.use(setSecurityHeaders)

  app.use(koa.route.get('/', function*() {
    const data = yield cached('database', loadDatabase)
    this.type = 'text/html'
    this.body = yield cached('home.pug', pugPage('home.pug'))(data)
  }))

  app.use(koa.route.get('/talks/:slug', function*(slug) {
    this.status = 301
    this.redirect(`/talks/${slug}/essay`)
  }))

  app.use(koa.route.get('/talks/:slug/essay', function*(slug) {
    const data = yield cached('database', loadDatabase)
    const talk = data.talks.find(talk => talk.slug === slug)
    if (!talk) {
      this.throw(404)
    }

    this.type = 'text/html'
    this.body = yield cached(`essay.pug & talks/${talk.date}--${slug}.md`,
      markdownPage('essay.pug', `talks/${talk.date}--${slug}.md`))(talk.code.language, talk)
  }))

  app.use(koa.route.get('/talks/:slug/presentation', function*(slug) {
    const data = yield cached('database', loadDatabase)
    const talk = data.talks.find(talk => talk.slug === slug && talk.presentation)
    if (!talk) {
      this.throw(404)
    }

    this.type = 'text/html'
    switch (talk.presentation.type) {
      case 'elm':
        this.body = yield cached('presentation-elm.pug', pugPage('presentation-elm.pug'))(talk)
        break
      case 'reveal.js':
        this.body = yield cached(`presentation-reveal.pug & talks/${talk.date}--${slug}.md`,
          markdownPage('presentation-reveal.pug', `talks/${talk.date}--${slug}.md`))(talk.code.language, talk)
        break
    }
  }))

  app.use(koa.route.get('/talks/:slug/video', function*(slug) {
    const data = yield cached('database', loadDatabase)
    const talk = data.talks.find(talk => talk.slug === slug && talk.video && talk.video.type === 'youtube')
    if (!talk) {
      this.throw(404)
    }

    this.type = 'text/html'
    this.body = yield cached('video.pug', pugPage('video.pug'))(talk)
  }))

  app.use(koa.route.get('/workshops/:slug', function*(slug) {
    const data = yield cached('database', loadDatabase)
    const workshop = data.workshops.find(event => event.slug === slug)
    if (!workshop) {
      this.throw(404)
    }

    this.type = 'text/html'
    this.body = yield cached(`events/${slug}.pug`, pugPage(`events/${slug}.pug`))(workshop)
  }))

  app.use(koa.route.get('/:file.css', function*(file) {
    this.type = 'text/css'
    this.body = (yield cached(`${file}.scss`, renderSass)({file: `src/${file}.scss`})).css
  }))

  const staticFile = (path, type, fileLocation = `src/assets/${path}`) => {
    app.use(koa.route.get(`/${path}`, function*() {
      this.type = type
      this.body = yield readFile(fileLocation)
    }))
  }

  staticFile('assets/talks/presentation.js', 'application/javascript', 'src/presentations/load.js')
  staticFile('assets/talks/99-problems/presentation.js', 'application/javascript', 'build/presentations/99-problems.js')

  staticFile('vendor/prismjs/prism.css', 'text/css', 'node_modules/prismjs/themes/prism.css')
  staticFile('vendor/prismjs/prism-okaidia.css', 'text/css', 'node_modules/prismjs/themes/prism-okaidia.css')
  staticFile('vendor/prismjs/prism.js', 'application/javascript', 'node_modules/prismjs/prism.js')

  staticFile('vendor/reveal.js/css/reveal.css', 'text/css', 'node_modules/reveal.js/css/reveal.css')
  staticFile('vendor/reveal.js/css/theme/white.css', 'text/css', 'node_modules/reveal.js/css/theme/white.css')
  staticFile('vendor/reveal.js/js/reveal.js', 'application/javascript', 'node_modules/reveal.js/js/reveal.js')
  staticFile('vendor/reveal.js/lib/js/head.min.js', 'application/javascript', 'node_modules/reveal.js/lib/js/head.min.js')

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

  return new Promise(resolve => {
    const server = app.listen(port, () => resolve(server))
  })
    .then(server => {
      console.log(JSON.stringify({
        message: 'Application started.',
        port: port,
        environment: environment
      }))

      return {
        stop: () => {
          server.close(() => {
            console.log(JSON.stringify({
              message: 'Application stopped.'
            }))
          })
        }
      }
    })
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
  this.set('Content-Security-Policy', 'default-src * data: \'unsafe-inline\' \'unsafe-eval\'')
  this.set('X-Frame-Options', 'DENY')
  this.set('X-XSS-Protection', '1; mode=block')
  yield next
}

const loadDatabase = function*() {
  const database = yaml.safeLoad(yield readFile('database.yaml'))
  database.talks = parseDates(database.talks)
  database.workshops = parseDates(database.workshops)

  const today = moment().startOf('day')
  database.upcomingWorkshops = database.workshops
    .filter(event => event.timestamp.isSameOrAfter(today))
  database.upcomingTalks = database.talks
    .filter(event => event.timestamp.isSameOrAfter(today))
  database.previousTalks = database.talks
    .filter(event => event.timestamp.isBefore(today) && event.slug)

  return database
}

const parseDates = (events = []) => {
  events
    .forEach(event => {
      if (!event.timestamp) {
        throw new Error(`The following event does not have a timestamp.\n${JSON.stringify(event, null, 2)}`)
      }
    })

  return events
    .map(event =>
      Object.assign({}, event, {timestamp: moment(event.timestamp)}))
    .map(event =>
      Object.assign({}, event, {
        date: event.timestamp.format('YYYY-MM-DD'),
        formattedDate: event.timestamp.format('dddd Do MMMM, YYYY')
      }))
}

const markdownPage = (layoutFile, viewFile) => function*(defaultLanguage, data) {
  const markdown = markdownIt({html: true, highlight: highlightCode(defaultLanguage)})
  const contents = yield readFile(`src/views/${viewFile}`, 'utf8')
  const renderedContents = markdown.render(contents)
  return yield pugPage(layoutFile)(Object.assign({contents: renderedContents}, data))
}

const pugPage = viewFile => function*(data) {
  return pug.renderFile(`src/views/${viewFile}`, Object.assign({}, data, {pretty: true}))
}

const highlightCode = defaultLanguage => (code, language) => {
  const languageToUse = language || defaultLanguage
  if (!prism.languages[languageToUse]) {
    try {
      require(`prismjs/components/prism-${languageToUse}`)
    } catch (error) {
      return ''
    }
  }
  return prism.highlight(code, prism.languages[languageToUse])
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

module.exports = {
  start
}
