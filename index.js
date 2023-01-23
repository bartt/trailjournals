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

app.listen(8000, () => console.log("Server Listening on Port 8000"))

