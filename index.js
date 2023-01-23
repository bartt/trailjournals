import express from 'express'
import { engine } from 'express-handlebars'
import cookieParser from 'cookie-parser'
import fs from 'fs'

const app = express()

app.engine('handlebars', engine({allowedProtoMethods: {name: true}}))
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

app.get('/proxy', (req, res) => {
  const id = normalizeId(req.query.id) 
  const href = `https://www.trailjournals.com/entry.cfm?id=${id}`
  res.send(href)
  // erb URI.open(href).read, :layout => false
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

app.listen(8000, () => console.log("Server Listening on Port 8000"))

