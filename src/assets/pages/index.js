/* eslint-env browser */
/* global moment */

;(() => {
  const run = () => {
    fetch('/database.json')
      .then(response => {
        if (response.status !== 200) {
          return response.text().then(text => {
            throw new Error(
              [
                '/database.json responded with an error:',
                `Status: ${response.status}`,
                'Body:',
                text,
              ].join('\n'),
            )
          })
        }
        return response.json()
      })
      .then(database => {
        database.talks = parseDates(database.talks)
        database.workshops = parseDates(database.workshops)

        const today = moment().startOf('day')
        database.upcomingWorkshops = database.workshops.filter(event =>
          event.timestamp.isSameOrAfter(today),
        )
        database.previousWorkshops = database.workshops.filter(event =>
          event.timestamp.isBefore(today),
        )
        database.upcomingTalks = database.talks.filter(event =>
          event.timestamp.isSameOrAfter(today),
        )
        database.previousTalks = database.talks.filter(event =>
          event.timestamp.isBefore(today),
        )

        return database
      })
      .then(database => {
        const section = document.querySelector('.upcoming-events')
        const message = document.querySelector('.upcoming-events .message')
        message.style.display = 'none'
        section.appendChild(upcoming('workshops', database.upcomingWorkshops))
        section.appendChild(upcoming('talks', database.upcomingTalks))
        section.appendChild(previous('workshops', database.previousWorkshops))
        section.appendChild(previous('talks', database.previousTalks))
      })
      .catch(error => {
        // eslint-disable-next-line no-console
        console.error(error)
        const message = document.querySelector('.upcoming-events .message')
        delete message.style.display
        message.classList.add('error')
        message.textContent =
          "I couldn't get information about upcoming events. I recommend you just tweet Samir instead."
      })
  }

  const upcoming = (title, events) => {
    const container = document.createElement('div')
    const header = document.createElement('header')
    const headerText = document.createElement('h2')
    headerText.textContent = `Upcoming ${title}`
    header.appendChild(headerText)
    container.appendChild(header)

    if (events.length === 0) {
      const body = document.createElement('p')
      body.textContent = `No upcoming ${title}.`
      container.appendChild(body)
    } else {
      events.forEach(event => {
        container.appendChild(eventElement(title, event))
      })
    }
    return container
  }

  const previous = (title, events) => {
    const container = document.createElement('div')
    if (events.length > 0) {
      const header = document.createElement('header')
      const headerText = document.createElement('h2')
      headerText.textContent = `Previous ${title}`
      header.appendChild(headerText)
      container.appendChild(header)

      events.forEach(event => {
        container.appendChild(eventElement(title, event))
      })
    }
    return container
  }

  const eventElement = (prefix, event) => {
    const container = document.createElement('article')
    container.classList.add('event')

    const header = document.createElement('h3')
    if (event.link || event.slug) {
      const headerLink = document.createElement('a')
      headerLink.href = event.link || `/${prefix}/${event.slug}`
      headerLink.textContent = event.title
      header.appendChild(headerLink)
    } else {
      header.textContent = event.title
    }
    container.appendChild(header)

    if (event.partner) {
      const partner = document.createElement('p')
      const partnerLink = document.createElement('a')
      partnerLink.href = event.partner.link
      partnerLink.textContent = event.partner.name
      partner.appendChild(document.createTextNode('with '))
      partner.appendChild(partnerLink)
      container.appendChild(partner)
    }

    const eventDetails = document.createElement('p')
    eventDetails.textContent =
      event.event && event.location
        ? `${event.event} @ ${event.location}`
        : event.event || event.location
    container.appendChild(eventDetails)

    const eventDate = document.createElement('p')
    eventDate.textContent = event.formattedDate
    container.appendChild(eventDate)

    if (event.slug || event.external || event.presentation || event.video) {
      const links = document.createElement('ul')
      links.classList.add('links')
      if (event.slug) {
        links.appendChild(
          eventLink(`/${prefix}/${event.slug}/essay`, 'Read as an essay'),
        )
      }
      if (event.presentation) {
        if (event.presentation.type === 'external') {
          links.appendChild(
            eventLink(event.presentation.link, 'Browse the presentation'),
          )
        } else {
          links.appendChild(
            eventLink(
              `/${prefix}/${event.slug}/presentation`,
              'Browse the presentation',
            ),
          )
        }
      }
      if (event.video) {
        if (event.video.type === 'external') {
          links.appendChild(eventLink(event.video.link, 'Watch the video'))
        } else {
          links.appendChild(
            eventLink(`/${prefix}/${event.slug}/video`, 'Watch the video'),
          )
        }
      }
      if (event.external) {
        links.appendChild(eventLink(event.external.link, event.external.text))
      }
      container.appendChild(links)
    }

    return container
  }

  const eventLink = (href, text) => {
    const listItem = document.createElement('li')
    const link = document.createElement('a')
    link.href = href
    link.textContent = text
    listItem.appendChild(link)
    return listItem
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

  run()
})()
