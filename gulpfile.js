const fs = require("fs");
const gulp = require("gulp");
const yaml = require("js-yaml");
const markdownIt = require("markdown-it");
const merge = require("merge-stream");
const moment = require("moment");
const sass = require("node-sass");
const path = require("path");
const pug = require("pug");
const prism = require("prismjs");
const through = require("through2");

gulp.task("default", () => {
  const database = loadDatabase();
  return merge(
    buildDatabase("database.yaml"),

    buildPug("src/views/index.pug", database),
    buildPug("src/views/bio.pug", database),

    ...database.talks
      .map(redirectEvent("talks"))
      .filter(event => event != null),
    ...database.talks.filter(talk => talk.slug && talk.essay).map(buildEssay),
    ...database.talks
      .filter(
        talk =>
          talk.slug &&
          talk.presentation &&
          talk.presentation.type !== "external",
      )
      .map(buildPresentation),
    ...database.talks
      .filter(talk => talk.slug && talk.video && talk.video.type === "youtube")
      .map(buildVideo),

    ...database.workshops
      .filter(talk => talk.slug)
      .map(redirectEvent("workshops"))
      .filter(event => event != null),
    ...database.workshops
      .filter(workshop => workshop.slug && workshop.essay)
      .map(buildWorkshop),

    gulp
      .src("src/site.scss")
      .pipe(compileSass())
      .pipe(gulp.dest("build")),
    gulp
      .src("src/talks.scss")
      .pipe(compileSass())
      .pipe(gulp.dest("build")),
    gulp
      .src("src/slides.scss")
      .pipe(compileSass())
      .pipe(gulp.dest("build")),

    staticFile("dat.json", "dat.json"),
    gulp
      .src("dat.json")
      .pipe(wellKnownDat())
      .pipe(gulp.dest("build")),

    staticFile("pages/index.js", "src/pages/index.js"),
    staticFile("talks/presentation.js", "src/presentations/load.js"),

    staticFile(
      "vendor/prismjs/prism.css",
      "node_modules/prismjs/themes/prism.css",
    ),
    staticFile(
      "vendor/prismjs/prism-okaidia.css",
      "node_modules/prismjs/themes/prism-okaidia.css",
    ),
    staticFile("vendor/prismjs/prism.js", "node_modules/prismjs/prism.js"),

    staticFile(
      "vendor/reveal.js/css/reveal.css",
      "node_modules/reveal.js/css/reveal.css",
    ),
    staticFile(
      "vendor/reveal.js/css/theme/white.css",
      "node_modules/reveal.js/css/theme/white.css",
    ),
    staticFile(
      "vendor/reveal.js/js/reveal.js",
      "node_modules/reveal.js/js/reveal.js",
    ),
    staticFile(
      "vendor/reveal.js/lib/js/head.min.js",
      "node_modules/reveal.js/lib/js/head.min.js",
    ),

    staticFile("src/assets/android-chrome-192x192.png"),
    staticFile("src/assets/android-chrome-512x512.png"),
    staticFile("src/assets/apple-touch-icon.png"),
    staticFile("src/assets/browserconfig.xml"),
    staticFile("src/assets/favicon-16x16.png"),
    staticFile("src/assets/favicon-32x32.png"),
    staticFile("src/assets/favicon.ico"),
    staticFile("src/assets/manifest.json"),
    staticFile("src/assets/mstile-150x150.png"),
    staticFile("src/assets/safari-pinned-tab.svg"),
  );
});

gulp.task("watch", () =>
  gulp.watch("src/**/*.{elm,js,md,pug,scss,yaml}", ["default"]),
);

const staticFile = (dest, src) => {
  if (src) {
    return gulp
      .src(src)
      .pipe(renameTo(path.basename(dest)))
      .pipe(gulp.dest(path.join("build", path.dirname(dest))));
  }
  const name = dest;
  return gulp.src(name).pipe(gulp.dest("build"));
};

const buildDatabase = file =>
  gulp
    .src(file)
    .pipe(yamlToJson())
    .pipe(gulp.dest("build"));

const buildPug = (file, data, dest = "build") =>
  gulp
    .src(file)
    .pipe(withData(data))
    .pipe(pugPage())
    .pipe(gulp.dest(dest));

const primaryEventLink = (prefix, event) => {
  if (event.essay) {
    return `/${prefix}/${event.slug}/essay.html`;
  }
  if (event.presentation) {
    if (event.presentation.type === "external") {
      return event.presentation.link;
    }
    return `/${prefix}/${event.slug}/presentation.html`;
  }
  if (event.video) {
    if (event.video.type === "external") {
      return event.video.link;
    }
    return `/${prefix}/${event.slug}/video.html`;
  }
  if (event.external) {
    return event.external.link;
  }
  return null;
};

const redirectEvent = prefix => event => {
  const link = primaryEventLink(prefix, event);
  if (!link) {
    return null;
  }
  return gulp
    .src("src/views/redirect.pug")
    .pipe(withData({destination: link}))
    .pipe(pugPage())
    .pipe(renameTo(`index.html`))
    .pipe(gulp.dest(`build/${prefix}/${event.slug}`));
};

const buildEssay = talk =>
  gulp
    .src(`src/views/talks/${talk.date}--${talk.slug}.md`)
    .pipe(withData(talk))
    .pipe(
      markdownPage(
        "src/views/essay.pug",
        "essay.html",
        talk.code && talk.code.language,
      ),
    )
    .pipe(gulp.dest(`build/talks/${talk.slug}`));

const buildPresentation = talk => {
  switch (talk.presentation.type) {
    case "elm":
      return gulp
        .src("src/views/presentation-elm.pug")
        .pipe(withData(talk))
        .pipe(pugPage("presentation.html"))
        .pipe(gulp.dest(`build/talks/${talk.slug}`));
    case "reveal.js":
      return gulp
        .src(`src/views/talks/${talk.date}--${talk.slug}.md`)
        .pipe(withData(talk))
        .pipe(
          markdownPage(
            "src/views/presentation-reveal.pug",
            "presentation.html",
            talk.code && talk.code.language,
          ),
        )
        .pipe(gulp.dest(`build/talks/${talk.slug}`));
    default:
      throw new Error(
        `Unknown presentation type: ${JSON.stringify(talk.presentation.type)}`,
      );
  }
};

const buildVideo = talk =>
  gulp
    .src("src/views/video.pug")
    .pipe(withData(talk))
    .pipe(pugPage("video.html"))
    .pipe(gulp.dest(`build/talks/${talk.slug}`));

const buildWorkshop = workshop =>
  gulp
    .src(`src/views/events/${workshop.slug}.pug`)
    .pipe(withData(workshop))
    .pipe(pugPage())
    .pipe(gulp.dest(`build/workshops`));

const pugPage = (filename = null) =>
  through.obj((file, encoding, callback) => {
    const pugContents = file.isBuffer()
      ? file.contents.toString(encoding)
      : file.contents;
    pug.render(
      pugContents,
      {...file.data, filename: file.path, pretty: true},
      (error, htmlContents) => {
        if (error) {
          callback(error);
          return;
        }
        file.contents = Buffer.from(htmlContents);
        file.path = filename
          ? path.join(path.dirname(file.path), filename)
          : file.path.replace(/\.pug$/, ".html");
        callback(null, file);
      },
    );
  });

const yamlToJson = () =>
  through.obj((file, encoding, callback) => {
    const contents = file.isBuffer()
      ? file.contents.toString(encoding)
      : file.contents;
    try {
      const object = yaml.safeLoad(contents);
      file.contents = Buffer.from(JSON.stringify(object, null, 2));
      file.path = file.path.replace(/\.ya?ml$/, ".json");
      callback(null, file);
    } catch (error) {
      callback(error);
    }
  });

const markdownPage = (layoutFile, filename, defaultLanguage) =>
  through.obj((file, encoding, callback) => {
    const markdown = markdownIt({
      html: true,
      highlight: highlightCode(defaultLanguage),
    });
    const contents = file.isBuffer()
      ? file.contents.toString(encoding)
      : file.contents;
    const renderedContents = markdown.render(contents);
    pug.renderFile(
      layoutFile,
      {...file.data, contents: renderedContents, pretty: true},
      (error, htmlContents) => {
        if (error) {
          callback(error);
          return;
        }
        file.contents = Buffer.from(htmlContents);
        file.path = path.join(path.dirname(file.path), filename);
        callback(null, file);
      },
    );
  });

const compileSass = () =>
  through.obj((file, encoding, callback) => {
    const contents = file.isBuffer()
      ? file.contents.toString(encoding)
      : file.contents;
    sass.render({data: contents, includePaths: ["src"]}, (error, result) => {
      if (error) {
        callback(error);
        return;
      }
      file.contents = result.css;
      file.path = file.path.replace(/\.s[ac]ss$/, ".css");
      callback(null, file);
    });
  });

const renameTo = filename =>
  through.obj((file, encoding, callback) => {
    file.path = path.join(path.dirname(file.path), filename);
    callback(null, file);
  });

const highlightCode = defaultLanguage => (code, language) => {
  const languageToUse = language || defaultLanguage;
  if (!prism.languages[languageToUse]) {
    try {
      // eslint-disable-next-line
      require(`prismjs/components/prism-${languageToUse}`);
    } catch (error) {
      return "";
    }
  }
  return prism.highlight(code, prism.languages[languageToUse]);
};

const withData = data =>
  through.obj((file, encoding, callback) => {
    file.data = data;
    callback(null, file);
  });

const wellKnownDat = () =>
  through.obj((file, encoding, callback) => {
    try {
      const contents = file.isBuffer()
        ? file.contents.toString(encoding)
        : file.contents;
      const {url} = JSON.parse(contents);
      if (!url) {
        throw new Error("No URL in the dat.json file.");
      }
      file.contents = Buffer.from(`${url}\n`);
      file.path = ".well-known/dat";
      callback(null, file);
    } catch (error) {
      callback(error);
    }
  });

const loadDatabase = () => {
  const database = yaml.safeLoad(fs.readFileSync("database.yaml"));
  database.talks = parseDates(database.talks);
  database.workshops = parseDates(database.workshops);
  return database;
};

const parseDates = (events = []) => {
  events.forEach(event => {
    if (!event.timestamp) {
      throw new Error(
        `The following event does not have a timestamp.\n${JSON.stringify(
          event,
          null,
          2,
        )}`,
      );
    }
  });

  return events
    .map(event =>
      Object.assign({}, event, {timestamp: moment(event.timestamp)}),
    )
    .map(event =>
      Object.assign({}, event, {
        date: event.timestamp.format("YYYY-MM-DD"),
        formattedDate: event.timestamp.format("dddd Do MMMM, YYYY"),
      }),
    );
};
