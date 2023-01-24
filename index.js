import debug from 'debug';
import express, {response} from 'express'
import {create} from 'express-handlebars'
import cookieParser from 'cookie-parser'
import fetch from 'node-fetch';
import fs from 'fs'
import RSS from 'rss'
import Parser from 'rss-parser';
import {createHmac} from 'node:crypto';
import {parse} from 'node-html-parser'

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
    logo,
    yingYang,
  })
})

app.get('/hiker', (req, res) => {
  const hikerId = req.query.id
  const feedUrl = hikerId ? `https://trailjournals.com/journal/rss/${hikerId}/xml` : req.query.url
  const hikerHref = `${req.protocol}://${req.hostname}${req.path}?id=${hikerId}`
  const entryHref = (entryId) => `${req.protocol}://${req.hostname}/entry?id=${entryId}&hiker_id=${hikerId}`
  fetch(feedUrl, fetchSettings).then(async (fetchRes) => {
    const feed = await new Parser().parseString(await fetchRes.text())
    const rss = new RSS({
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

app.get('/entry', async (req, res) => { 
  const entryId = normalizeId(req.query.id)
  const entryHref = `https://trailjournals.com/journal/entry/${entryId}`
  const fetchRes = await fetch(entryHref, fetchSettings)
  const entry = parse(await fetchRes.text())

  const title = entry.querySelector('.journal-title').text.replace(/\d{4}/, "$1 ")
  const entryTitle = entry.querySelector('.entry-title')
  const date = entry.querySelector('.entry-date').text.trim()
  const hikerId = req.query.hiker_id || entry.querySelector('a[href*=rss]').attrs.href.split('/').splice(-2).shift()
  const hikerHref = `${req.protocol}://${req.hostname}/hiker?id=${hikerId}`

  const stats = entry.querySelectorAll('.panel-heading .row:nth-child(n+2) span').map((stat) => stat.text.trim())
  const imgHref = entry.querySelector('.entry img').attrs.src
  const avatarHref = entry.querySelector('.journal-thumbnail img') && entry.querySelector('.journal-thumbnail img').attrs.src
  const signature = entry.querySelector('.journal-signature') && entry.querySelector('.journal-signature').text.trim()

  let body = ""
  for (const node of entry.querySelector('.entry').childNodes) {
    if (['text', 'p', 'h4'].includes((node.tagName || '').toLowerCase())) {
      const text = node.text.trim()
      // Filter out blank nodes 
      if (text.length > 0 && !/^\W+$/.test(text)) {
        // Directly link to images on trailjournals.com. Don't proxy.
        for (const img of node.querySelectorAll('img')) {
          img.setAttribute('class', 'entry-content-asset')
          if (!/\/\/trailjournals.com/.test(img.attrs.src) && !/^data:/.test(img.attrs.src)) {
            img.setAttribute('src', `//trailjournals.com${img.attrs.src}`) 
          }
        }
        // Append augmented markup; `setAttribute` also changes `outerHTML` of the parent node.
        body += node.outerHTML
      }
    }
  }

  res.render('entry', {
    title, 
    theme: req.cookies.theme || 'light',
    yingYang,
    entryId,
    entryTitle,
    date,
    hikerId,
    hikerHref,
    stats,
    avatarHref,
    imgHref,
    body,
    signature,
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
    yingYang,
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

app.listen(9292, () => console.log("Server Listening on Port 9292"))