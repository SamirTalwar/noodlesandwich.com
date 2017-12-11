const fs = require('fs')
const Koa = require('koa')
const route = require('koa-route')
const markdownIt = require('markdown-it')
const moment = require('moment')
const pug = require('pug')
const prism = require('prismjs')
const sass = require('node-sass')
const yaml = require('js-yaml')

const Cache = require('./cache')
const {denodeify} = require('./promises')

const start = ({environment, log, port}) => {
  const inProduction = environment === 'production'

  const cached = Cache(log, inProduction)
  const loadData = cached('database', loadDatabase)

  const app = new Koa()
  app.use(timeResponse(log))
  app.use(setSecurityHeaders)

  app.use(
    route.get('/', async context => {
      const data = await loadData()
      context.type = 'text/html'
      context.body = await cached('home.pug', pugPage('home.pug'))(data)
    }),
  )

  app.use(
    route.get('/bio', async context => {
      const data = await loadData()
      context.type = 'text/html'
      context.body = await cached('bio.pug', pugPage('bio.pug'))(data)
    }),
  )

  app.use(
    route.get('/talks/:slug', (context, slug) => {
      context.status = 301
      context.redirect(`/talks/${slug}/essay`)
    }),
  )

  app.use(
    route.get('/talks/:slug/essay', async (context, slug) => {
      const data = await loadData()
      const talk = data.talks.find(t => t.slug === slug)
      if (!talk) {
        context.throw(404)
      }

      context.type = 'text/html'
      context.body = await cached(
        `essay.pug & talks/${talk.date}--${slug}.md`,
        markdownPage('essay.pug', `talks/${talk.date}--${slug}.md`),
      )(talk.code.language, talk)
    }),
  )

  app.use(
    route.get('/talks/:slug/presentation', async (context, slug) => {
      const data = await loadData()
      const talk = data.talks.find(t => t.slug === slug && t.presentation)
      if (!talk) {
        context.throw(404)
      }

      context.type = 'text/html'
      switch (talk.presentation.type) {
        case 'elm':
          context.body = await cached(
            'presentation-elm.pug',
            pugPage('presentation-elm.pug'),
          )(talk)
          break
        case 'reveal.js':
          context.body = await cached(
            `presentation-reveal.pug & talks/${talk.date}--${slug}.md`,
            markdownPage(
              'presentation-reveal.pug',
              `talks/${talk.date}--${slug}.md`,
            ),
          )(talk.code.language, talk)
          break
        default:
          context.throw(500, 'Unknown presentation type.')
      }
    }),
  )

  app.use(
    route.get('/talks/:slug/video', async (context, slug) => {
      const data = await loadData()
      const talk = data.talks.find(
        t => t.slug === slug && t.video && t.video.type === 'youtube',
      )
      if (!talk) {
        context.throw(404)
      }

      context.type = 'text/html'
      context.body = await cached('video.pug', pugPage('video.pug'))(talk)
    }),
  )

  app.use(
    route.get('/workshops/:slug', async (context, slug) => {
      const data = await loadData()
      const workshop = data.workshops.find(event => event.slug === slug)
      if (!workshop) {
        context.throw(404)
      }

      context.type = 'text/html'
      context.body = await cached(
        `events/${slug}.pug`,
        pugPage(`events/${slug}.pug`),
      )(workshop)
    }),
  )

  app.use(
    route.get('/:file.css', async (context, file) => {
      context.type = 'text/css'
      context.body = (await cached(`${file}.scss`, renderSass)({
        file: `src/${file}.scss`,
      })).css
    }),
  )

  const staticFile = (path, type, fileLocation = `src/assets/${path}`) => {
    app.use(
      route.get(`/${path}`, async context => {
        context.type = type
        context.body = await readFile(fileLocation)
      }),
    )
  }

  staticFile(
    'assets/talks/presentation.js',
    'application/javascript',
    'src/presentations/load.js',
  )
  staticFile(
    'assets/talks/99-problems/presentation.js',
    'application/javascript',
    'build/presentations/99-problems.js',
  )

  staticFile(
    'vendor/prismjs/prism.css',
    'text/css',
    'node_modules/prismjs/themes/prism.css',
  )
  staticFile(
    'vendor/prismjs/prism-okaidia.css',
    'text/css',
    'node_modules/prismjs/themes/prism-okaidia.css',
  )
  staticFile(
    'vendor/prismjs/prism.js',
    'application/javascript',
    'node_modules/prismjs/prism.js',
  )

  staticFile(
    'vendor/reveal.js/css/reveal.css',
    'text/css',
    'node_modules/reveal.js/css/reveal.css',
  )
  staticFile(
    'vendor/reveal.js/css/theme/white.css',
    'text/css',
    'node_modules/reveal.js/css/theme/white.css',
  )
  staticFile(
    'vendor/reveal.js/js/reveal.js',
    'application/javascript',
    'node_modules/reveal.js/js/reveal.js',
  )
  staticFile(
    'vendor/reveal.js/lib/js/head.min.js',
    'application/javascript',
    'node_modules/reveal.js/lib/js/head.min.js',
  )

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
  }).then(server => {
    log(
      JSON.stringify({
        message: 'Application started.',
        port,
        environment,
      }),
    )

    return {
      stop: () =>
        new Promise((resolve, reject) => {
          server.close(error => {
            if (error) {
              reject(error)
              return
            }

            log(
              JSON.stringify({
                message: 'Application stopped.',
              }),
            )
            resolve()
          })
        }),
    }
  })
}

const timeResponse = log => async (context, next) => {
  const startTime = new Date()
  await next()
  const responseTime = new Date() - startTime
  log(
    JSON.stringify({
      request: {
        method: context.method,
        url: context.url,
      },
      response: {
        status: context.response.status,
        message: context.response.message,
        time: responseTime,
      },
    }),
  )
}

const setSecurityHeaders = (context, next) => {
  context.set(
    'Content-Security-Policy',
    "default-src * data: 'unsafe-inline' 'unsafe-eval'",
  )
  context.set('X-Frame-Options', 'DENY')
  context.set('X-XSS-Protection', '1; mode=block')
  return next()
}

const loadDatabase = async () => {
  const database = yaml.safeLoad(await readFile('database.yaml'))
  database.talks = parseDates(database.talks)
  database.workshops = parseDates(database.workshops)

  const today = moment().startOf('day')
  database.upcomingWorkshops = database.workshops.filter(event =>
    event.timestamp.isSameOrAfter(today),
  )
  database.previousWorkshops = database.workshops.filter(
    event => event.timestamp.isBefore(today) && event.external,
  )
  database.upcomingTalks = database.talks.filter(event =>
    event.timestamp.isSameOrAfter(today),
  )
  database.previousTalks = database.talks.filter(
    event => event.timestamp.isBefore(today) && event.slug,
  )

  return database
}

const parseDates = (events = []) => {
  events.forEach(event => {
    if (!event.timestamp) {
      throw new Error(
        `The following event does not have a timestamp.\n${JSON.stringify(
          event,
          null,
          2,
        )}`,
      )
    }
  })

  return events
    .map(event =>
      Object.assign({}, event, {timestamp: moment(event.timestamp)}),
    )
    .map(event =>
      Object.assign({}, event, {
        date: event.timestamp.format('YYYY-MM-DD'),
        formattedDate: event.timestamp.format('dddd Do MMMM, YYYY'),
      }),
    )
}

const markdownPage = (layoutFile, viewFile) => async (
  defaultLanguage,
  data,
) => {
  const markdown = markdownIt({
    html: true,
    highlight: highlightCode(defaultLanguage),
  })
  const contents = await readFile(`src/views/${viewFile}`, 'utf8')
  const renderedContents = markdown.render(contents)
  return pugPage(layoutFile)(Object.assign({contents: renderedContents}, data))
}

const pugPage = viewFile => data =>
  pug.renderFile(
    `src/views/${viewFile}`,
    Object.assign({}, data, {pretty: true}),
  )

const highlightCode = defaultLanguage => (code, language) => {
  const languageToUse = language || defaultLanguage
  if (!prism.languages[languageToUse]) {
    try {
      // eslint-disable-next-line
      require(`prismjs/components/prism-${languageToUse}`)
    } catch (error) {
      return ''
    }
  }
  return prism.highlight(code, prism.languages[languageToUse])
}

const readFile = denodeify(fs.readFile)
const renderSass = denodeify(sass.render)

module.exports = {
  start,
}
