import debug from 'debug';
import express, { response } from 'express'
import { create } from 'express-handlebars'
import cookieParser from 'cookie-parser'
import fetch from 'node-fetch';
import fs from 'fs'
import RSS from 'rss'
import Parser from 'rss-parser';
import {createHmac} from 'node:crypto';

const DIGEST_KEY = 'super secret'
const app = express()
const logger = debug('trailjournals');
const fetchSettings = {
  headers: {
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:97.0) Gecko/20100101 Firefox/97.0',
  }
};

const handlebars = create({
  helpers: {
    isRelative(value) {
      const re = new RegExp('^\/')
      return !re.test(value)
    }
  }
})
app.engine('handlebars', handlebars.engine)
app.set("view engine", "handlebars")
app.set('views', './views')
app.use(cookieParser())
app.use(express.static('public'))

const logo = fs.readFileSync('public/favicon.svg')
const yingYang = fs.readFileSync('public/ying-yang.svg')

app.get("/", (req, res) => {
  const currentYear = (new Date()).getFullYear()
  res.render("index", {
    theme: req.cookies.theme || 'light',
    title: "Trailjournals",
    trails: [
      { abbr: 'AT', path: 'appalachian_trail' },
      { abbr: 'CDT', path: 'continental_divide_trail' },
      { abbr: 'PCT', path: 'pacific_crest_trail' }
    ],
    years: [...Array(4)].map((_, offset) => currentYear - offset).reverse(),
    logo: logo,
    yingYang: yingYang
  })
})

app.get('/hiker', (req, res) => {
  const hikerId = req.query.id
  const feedUrl = hikerId ? `https://trailjournals.com/journal/rss/${hikerId}/xml` : req.query.url
  const hikerHref = `${req.protocol}://${req.hostname}${req.path}?id=${hikerId}`
  const entryHref = (entryId) => `${req.protocol}://${req.hostname}/entry?id=${entryId}&hiker_id=${hikerId}`
  fetch(feedUrl, fetchSettings).then(async (fetchRes) => {
    let feed = await new Parser().parseString(await fetchRes.text())
    let rss = new RSS({
      title: feed.title,
      description: feed.description,
      link: feed.link,
      feed_url: hikerHref,
      site_url: `${req.protocol}://${req.hostname}`
    })
    for (const item of feed.items) {
      log(item)
      const hmac = createHmac('sha256', DIGEST_KEY);
      hmac.update(item.link)
      const pubDate = item.pubDate.match(/\d\d\d\d-\d\d-\d\d/)[0]
      rss.item({
        title: item.title,
        date: Date.parse(pubDate),
        description: item.content,
        url: entryHref(item.link.split('/').pop()),
        guid: hmac.digest('hex')
      })
    }
    log(rss)
    res.status(200)
    res.type('text/xml')
    res.send(rss.xml({indent: true}))
  })
})

app.get('/entry', (req, res) => { 
  res.render('entry', {
    title: "TESTING", 
    theme: req.cookies.theme || 'light',
    yingYang: yingYang,
    // entryTitle:
    // entryId:
    // date:
    // hikerId:
    // hikerHref:
    // avatarHref:
    // stats:
    // imgHref:
    // body:
    // signature:
    // request:
  })
})

app.get('/proxy', (req, res) => {
  const id = normalizeId(req.query.id) 
  const url = `https://www.trailjournals.com/entry.cfm?id=${id}`
  fetch(url, fetchSettings).then(async (fetchRes) => {
    const body = await fetchRes.text()
    res.status(fetchRes.status)
    res.send(body)
  })
})

// Prevent 404 errors for the images in proxied trailjournals.com pages.
app.get('/images/*', (req, res) => {
  res.status(200)
  res.send()
})

function errorHandler(err, req, res, next) {
  res.status(500)
  res.render('error', {
    title: 'Internal Server Error',
    theme: req.cookies.theme || 'light',
    yingYang: yingYang,
    error: err
  })
}

app.use(errorHandler)

function normalizeId(id) {
  const matchData = id.match(/(\d+)$/) 
  return matchData.length > 0 ? matchData[0] : id
}

function log(msg) {
  if (debug.enabled) {
    logger(msg);
  }
}

app.listen(8000, () => console.log("Server Listening on Port 8000"))

