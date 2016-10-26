*With [@sleepyfox][].*

[@sleepyfox]: https://twitter.com/sleepyfox

---

We're building a game for Xbox Two: <strong title="Which is definitely not related to &quot;Destiny&quot;.">Fate</strong>. One of the game modes is called the… um… <strong>Trials of Anubis</strong>.

<figure class="image">
  <img alt="Fate cover art" src="https://assets.noodlesandwich.com/talks/staying-lean-with-application-logs/cover-art.jpg"/>
  <figcaption>Copyright me, 2016</figcaption>
</figure>

Here's how it works.

  * You have two teams, *Alpha* and *Bravo*, each of three players.
  * Each team is trying to defeat the other one.
  * If you take another player down, they don't revive in the same round.
  * Players *can* bring their teammates back up, but it's time-consuming.
  * If all the players on the team are taken down, that team loses.
  * Best out of three rounds wins the match.

## About the infrastructure

It used to look like this:

<div class="image">

![Monolith](https://assets.noodlesandwich.com/talks/staying-lean-with-application-logs/monolith.png)

</div>

I know, pretty, right.

As you can see, we have one application with five components. Unfortunately, it doesn't really scale past a couple of games.

We initially looked into re-working the application to be completely multi-threaded. That made a bit of sense, but there's an issue with threading: it's still on one machine. You can only get so far with this until you need to scale out anyway.

Next up: scale out the monolith.

<div class="image">

![Distributed monolith](https://assets.noodlesandwich.com/talks/staying-lean-with-application-logs/monolith-distributed.png)

</div>

Sure, it works fairly well, but the problem is that you just need a lot more CPU time dedicated to gameplay; scoring and managing players is pretty lightweight, and matchmaking is intense but only for very short bursts. In addition, we still needed to federate the data across servers, because otherwise players are stuck on one single server.

So we rewrote it to use services. That went as well as you might expect.

<div class="image">

![Services with a centralised database](https://assets.noodlesandwich.com/talks/staying-lean-with-application-logs/services-centralised-database.png)

</div>

Communication via the database. What an excellent plan. That worked for about twenty seconds before we ran into consistency problems.

So we moved to services communicating directly with each other. We looked at the literature and it appears that the conventional way is to make them talk over HTTP. So we did.

<div class="image">

![Decentralised services](https://assets.noodlesandwich.com/talks/staying-lean-with-application-logs/services-decentralised.png)

</div>

Or rather, we tried to. But with all the additional infrastructure required to handle and debug service HTTP connections, it got real complicated real fast.

Let's blow up the Gameplay service.

<div class="image">

![Decentralised services](https://assets.noodlesandwich.com/talks/staying-lean-with-application-logs/services-decentralised-gameplay.png)

</div>

Now, observe the components of this service. First of all, note that four out of six are just about handling the HTTP server and various clients. Of course, the game loop is huge, and could be broken down further, but that's our bread and butter. None of the HTTP stuff makes us money; it's just [*waste*][Muda].

And it's sprawling. Every service in our game needs the same components, designed slightly differently. Right now we're just looking at one game mode among many.

You see, the problem is that handling large amounts of computation and data like this is inherently complicated. Splitting it up into services just moves the complication into a shape that makes a little more sense to us, but it definitely doesn't make it go away.

What we need is a model that works *with* the <span title="sometimes known as &quot;microservices&quot; for some reason">service-oriented architecture</span> we have in place.

[Muda]: https://en.wikipedia.org/wiki/Muda_(Japanese_term)

## Event sourcing

What if, rather than *consuming* from other services, each service *published* every single event?

Each service would push events to some sort of event bus, which would then push those events out to other nodes which had subscribed to those kinds of events.

We still need the client, so we can talk to this event bus, but we don't need an HTTP server any more. In addition, we don't need the logging that goes along with it. We can let the event bus handle that, storing them somewhere so we can replay them later.

But we can be leaner.

The problem here is that our application doesn't talk to an event bus right now. Retrofitting that will be a huge undertaking. However, our application *does* publish events… to STDOUT.

### STDOUT?

Yup, it logs. A lot. We can consider those log lines to be events.

So, we're logging. All we need to do now is to push those events to a log collector such as [Fluentd][] or [Logstash][], and have it push them somewhere that can push them outwards again.

A log-powered event bus. It'll never work.

Let's do it.

[Fluentd]: http://www.fluentd.org/
[Logstash]: https://www.elastic.co/products/logstash

## Let's see it work.

Go and clone [SamirTalwar/logs-as-the-event-source][]. I'll wait.

Done? Great. You'll also need [Docker][Install Docker] and [Docker Compose][Install Docker Compose].

Let's start up Fluentd. We're going to pipe STDOUT to there. It's also running a WebSocket server, which will act as a very basic event publisher. In the real world, you'll want something that can scale a little better.

```sh
docker-compose -f docker-compose.fluentd.yml build
docker-compose -f docker-compose.fluentd.yml up
```

Give it 10 seconds or so to warm up, then we'll be ready to start the application. It's going to simulate a Trials of Anubis match. The Players service is just playing canned events, but all the others are listening and responding appropriately.

Fire it up.

```sh
docker-compose build
docker-compose up
```

The output will look something like this:

```text
Starting logging_scoring_1
Starting logging_gameplay_1
Starting logging_players_1
Starting logging_matchmaker_1
Attaching to logging_scoring_1, logging_matchmaker_1, logging_gameplay_1, logging_players_1
scoring_1     | {"type":"ServiceStarted","service":"scoring","hostname":"5012e39b5b33"}
matchmaker_1  | {"type":"ServiceStarted","service":"matchmaker","hostname":"ed2947f68981"}
gameplay_1    | {"type":"ServiceStarted","service":"gameplay","hostname":"6dd9ae1f908a"}
players_1     | {"type":"Startup","service":"players","hostname":"6928c0e3ed72"}
players_1     | {"type":"PlayerJoined","player":{"id":1,"name":"A"}}
players_1     | {"type":"PlayerJoined","player":{"id":2,"name":"B"}}
players_1     | {"type":"PlayerJoined","player":{"id":3,"name":"C"}}
players_1     | {"type":"PlayerJoined","player":{"id":4,"name":"D"}}
players_1     | {"type":"PlayerJoined","player":{"id":5,"name":"E"}}
players_1     | {"type":"PlayerJoined","player":{"id":6,"name":"F"}}
matchmaker_1  | {"type":"MatchStarted","match":{"id":1,"teams":{"alpha":{"players":[{"id":1,"name":"A"},{"id":3,"name":"C"},{"id":5,"name":"E"}]},"bravo":{"players":[{"id":2,"name":"B"},{"id":4,"name":"D"},{"id":6,"name":"F"}]}}}}
matchmaker_1  | {"type":"MatchRoundStarted","match":{"id":1,"teams":{"alpha":{"players":[{"id":1,"name":"A"},{"id":3,"name":"C"},{"id":5,"name":"E"}]},"bravo":{"players":[{"id":2,"name":"B"},{"id":4,"name":"D"},{"id":6,"name":"F"}]}},"round":1}}
gameplay_1    | {"type":"GamePlayerDown","match":{"id":1},"player":2}
gameplay_1    | {"type":"GamePlayerDown","match":{"id":1},"player":5}
gameplay_1    | {"type":"GamePlayerUp","match":{"id":1},"player":2}
gameplay_1    | {"type":"GamePlayerDown","match":{"id":1},"player":6}
gameplay_1    | {"type":"GamePlayerDown","match":{"id":1},"player":3}
gameplay_1    | {"type":"GamePlayerDown","match":{"id":1},"player":1}
scoring_1     | {"type":"ScoringRoundWon","match":{"id":1},"round":1,"winner":"bravo"}
matchmaker_1  | {"type":"MatchRoundEnded","match":{"id":1,"teams":{"alpha":{"players":[{"id":1,"name":"A"},{"id":3,"name":"C"},{"id":5,"name":"E"}]},"bravo":{"players":[{"id":2,"name":"B"},{"id":4,"name":"D"},{"id":6,"name":"F"}]}},"round":1}}
matchmaker_1  | {"type":"MatchRoundStarted","match":{"id":1,"teams":{"alpha":{"players":[{"id":1,"name":"A"},{"id":3,"name":"C"},{"id":5,"name":"E"}]},"bravo":{"players":[{"id":2,"name":"B"},{"id":4,"name":"D"},{"id":6,"name":"F"}]}},"round":2}}
gameplay_1    | {"type":"GamePlayerDown","match":{"id":1},"player":2}
gameplay_1    | {"type":"GamePlayerUp","match":{"id":1},"player":2}
gameplay_1    | {"type":"GamePlayerDown","match":{"id":1},"player":2}
gameplay_1    | {"type":"GamePlayerDown","match":{"id":1},"player":4}
gameplay_1    | {"type":"GamePlayerDown","match":{"id":1},"player":5}
gameplay_1    | {"type":"GamePlayerDown","match":{"id":1},"player":6}
scoring_1     | {"type":"ScoringRoundWon","match":{"id":1},"round":2,"winner":"alpha"}
matchmaker_1  | {"type":"MatchRoundEnded","match":{"id":1,"teams":{"alpha":{"players":[{"id":1,"name":"A"},{"id":3,"name":"C"},{"id":5,"name":"E"}]},"bravo":{"players":[{"id":2,"name":"B"},{"id":4,"name":"D"},{"id":6,"name":"F"}]}},"round":2}}
matchmaker_1  | {"type":"MatchRoundStarted","match":{"id":1,"teams":{"alpha":{"players":[{"id":1,"name":"A"},{"id":3,"name":"C"},{"id":5,"name":"E"}]},"bravo":{"players":[{"id":2,"name":"B"},{"id":4,"name":"D"},{"id":6,"name":"F"}]}},"round":3}}
gameplay_1    | {"type":"GamePlayerDown","match":{"id":1},"player":1}
gameplay_1    | {"type":"GamePlayerDown","match":{"id":1},"player":4}
gameplay_1    | {"type":"GamePlayerDown","match":{"id":1},"player":5}
gameplay_1    | {"type":"GamePlayerDown","match":{"id":1},"player":6}
gameplay_1    | {"type":"GamePlayerDown","match":{"id":1},"player":2}
scoring_1     | {"type":"ScoringRoundWon","match":{"id":1},"round":3,"winner":"alpha"}
scoring_1     | {"type":"ScoringMatchWon","match":{"id":1},"winner":"alpha"}
matchmaker_1  | {"type":"MatchRoundEnded","match":{"id":1,"teams":{"alpha":{"players":[{"id":1,"name":"A"},{"id":3,"name":"C"},{"id":5,"name":"E"}]},"bravo":{"players":[{"id":2,"name":"B"},{"id":4,"name":"D"},{"id":6,"name":"F"}]}},"round":3}}
matchmaker_1  | {"type":"MatchEnd","match":{"id":1,"teams":{"alpha":{"players":[{"id":1,"name":"A"},{"id":3,"name":"C"},{"id":5,"name":"E"}]},"bravo":{"players":[{"id":2,"name":"B"},{"id":4,"name":"D"},{"id":6,"name":"F"}]}},"round":3,"winner":"alpha"}}
```

When the match ends, hit *Ctrl+C* to terminate the containers.

Docker Compose is aggregating the logs that get pumped out, but they're also going to Fluentd. The *scoring* service is listening to those events, storing state, and occasionally sending out its own by logging in exactly the same fashion.

Something like this:

```
const ws = new WebSocket(process.env.WEBSOCKET)
ws.on('error', report)

ws.on('message', attempt(data => {
  const event = JSON.parse(data)[1].event
  const handle = handlers[event.type] || noHandler
  handle(event)
}))

const handlers = {
  ...
  'GamePlayerDown': event => {
    const match = matches.get(event.match.id)
    match.playersUp.delete(event.player)
    checkRoundWinner(match)
  },
  ...
}

const checkRoundWinner = match => {
  Teams.forEach(team => {
    if (!match.teams[team].players.some(player => match.playersUp.has(player))) {
      console.log(JSON.stringify({
        type: 'ScoringRoundWinner',
        match: {
          id: match.id
        },
        round: match.round,
        winner: other(team)
      }))
    }
  })
}
```

That's a bit of a mouthful, but you'll be able to figure it out. Basically, it's listening for events over a WebSocket, and when it gets one with, for example, a type of `'GamePlayerDown'`, it removes that player from its set of `playersUp`. It then checks each team to see if that team has any players up at all. If not, the other team must have won, so it publishes an event.

Of course, it can listen to its own events, and it does.

```
const handlers = {
  ...
  'ScoringRoundWinner': event => {
    const match = matches.get(event.match.id)
    match.teams[event.winner].score += 1
    checkMatchWinner(match)
  },
  ...
}
```

When it sends a `'ScoringRoundWinner'` event, that triggers the event handler again, and we trap that event too, this time to figure out if we've won enough rounds to win the match.

[SamirTalwar/logs-as-the-event-source]: https://github.com/SamirTalwar/logs-as-the-event-source
[Install Docker]: https://www.docker.com/products/docker
[Install Docker Compose]: https://docs.docker.com/compose/install/

## What's in a log?

There are a few important things about our logs that make them amenable to this kind of development.

First of all, they're **machine-readable first**, human-readable second. We log in JSON, not any other way. We can easily convert from machine-readable logs to human-readable ones, so this is only an issue if you're reading them directly. Tools such as [Kibana][] will help a lot here.

Secondly, we don't worry about any of the typical features that a logging framework gives you. The way we log doesn't support:

  * filtering by severity level,
  * log rotation,
  * multiple formats,
  * or even logging to a file.

We just push information out on STDOUT and let the logging service, Fluentd, handle the rest. If we want to store the logs, we use a log store as its own dedicated service.

Thirdly, every log item has a type, which dictates the structure of the rest of the item. This structure is a contract, and it won't change without warning all consumers. And yes, that includes your ops team.

Fourthly, and most importantly, we've thought hard about what we log. We log every notable event in the system, including startup, errors and exceptions.

Now, there's probably more that needs to be done here. Our event structure *will* change eventually, and so a version number of sorts would be useful. Often, you'll also need an upgrade mechanism for replaying old events, although in the case of this video game, that's only important for our own analytics, not gameplay. In addition, scaling will need some thought, like how to make sure that the same event isn't handled twice by two different instances of the same service. But for getting ourselves off the ground,

All that said, getting started is *cheap*. After all, logging JSON is just a few lines of code in any language.

[Kibana]: https://www.elastic.co/products/kibana

### Don't repeat yourself

Our events here are pretty simple. However, in your typical web application, context is important, and it's annoying to have to duplicate your logging code everywhere. So at [Your Golf Travel][], @sleepyfox and I wrote a logging library [which is now on GitHub][ygt/microservice-logging]. It enforces a bit of convention—every log item has an event type, severity and timestamp.

You use it something like this:

```
const Logger = require('./logger')

const log = new Logger({
  now: Date.now,
  output: console,
  events: {
    startup: 'startup',
    httpRequest: 'HTTP request',
    database: 'database'
  }
}).with({service: 'my super service'})

log.startup.info({
  message: 'Ready to go.',
  port: 8080
})

// later on

const requestLog = log.with({request_id: '126bb6fa-28a2-470f-b013-eefbf9182b2d'})
requestLog.database.error({
  message: 'Connection failed.'
})
requestLog.httpRequest.info({
  request: {method: 'GET'},
  response: {status: 500}
})
```

And the output looks like this:

```json
{"timestamp":1474443152917,"event_type":"startup","severity":"INFO","service":"my super service","message":"Ready to go.","port":8080}
{"timestamp":1474443152920,"event_type":"database","severity":"ERROR","service":"my super service","request_id":"126bb6fa-28a2-470f-b013-eefbf9182b2d","message":"Connection failed."}
{"timestamp":1474443152921,"event_type":"HTTP request","severity":"INFO","service":"my super service","request_id":"126bb6fa-28a2-470f-b013-eefbf9182b2d","request":{"method":"GET"},"response":{"status":500}}
```

As you can see, it's really easy to add extra information to the log once and have it repeat itself later, helping you correlate log items. At the time of writing, the open-source extraction is very much a work in progress, so we could use a bit of help to get it off the ground.

[Your Golf Travel]: http://palatinategroup.com/
[ygt/microservice-logging]: https://github.com/ygt/microservice-logging

## In closing

By using our logs as an event stream, we've checked a lot of boxes.

  * We have a log of all events in the system.
  * There's real-time reactive behaviour across services.
  * The stateless services are completely scalable, and there's patterns for scaling the stateful ones.
  * Adding new services that derive information from the data requires no modifications to the existing ones.
  * We have a model for handling catastrophic failure, by spinning up replacement systems and simply replaying the events.

And you know my favourite?

We've come this far without any database at all.

Obviously, Fluentd as a server won't scale, but once you've collected the events in one place, you can pipe them wherever you want. Push them through an event stream that will scale with the rest of your architecture, like [Kafka][]. Store them in [Elasticsearch][] or dump them on [Amazon S3][]. And when you really do need that database, you can populate it from a single source of truth in exactly the same way.

But until then, stay lean.

[Kafka]: https://kafka.apache.org/
[Elasticsearch]: https://www.elastic.co/products/elasticsearch
[Amazon S3]: https://aws.amazon.com/s3/
