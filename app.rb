require 'sinatra/base'
require 'nokogiri'
require 'open-uri'
require 'openssl'
require 'time'

DIGEST_KEY = 'super secret'

class TrailJournals < Sinatra::Base
  configure do
    enable :logging
  end

  get '/pct', :provides => %w(rss atom xml) do

    feed = Nokogiri::XML(open('http://www.trailjournals.com/rss/index.cfm'))
    href = "#{request.scheme}//#{request.host}:#{request.port}#{request.path}"
    entry_href = "#{request.scheme}://#{request.host}:#{request.port}/entry?id="

    nokogiri do |xml|
      xml.rss('version' => '2.0', 'xmlns:atom' => 'http://www.w3.org/2005/Atom') do
        channel do
          xml['atom'].link('href' => href, 'rel' => 'self', 'type' => 'application/rss+xml')
          title "#{feed.xpath('/rss/channel/title').text} : Pacific Crest Trail"
          link feed.xpath('/rss/channel/link').text
          description 'Latest PCT posts on trailjournals.com'
          feed.xpath('/rss/channel/item[contains(.,"Pacific")]').each do |post|
            item {
              title post.xpath('./title').text
              pubDate DateTime.parse(post.xpath('./pubDate').text).strftime('%a, %d %b %Y %H:%M:%S %z')
              orig_link = post.xpath('./link')
              print_link = entry_href + orig_link.text.split('=').pop
              link print_link
              description post.xpath('./description').text
              guid(OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), DIGEST_KEY, orig_link.to_s), 'isPermaLink' => 'false')
            }
          end
        end
      end
    end
  end

  get '/hiker', :provides => %w(rss atom xml) do

    url = params['id'] ? "http://www.trailjournals.com/journal/rss/#{params['id']}/xml" : params['url']
    feed = Nokogiri::XML(open(url))
    hiker_id = params['id'] || url.split('/')[-2]
    href = "#{request.scheme}://#{request.host}:#{request.port}#{request.path}?id=#{hiker_id}"
    entry_href = "#{request.scheme}://#{request.host}:#{request.port}/entry?id=%d&hiker_id=#{hiker_id}"

    nokogiri do |xml|
      xml.rss('version' => '2.0', 'xmlns:atom' => 'http://www.w3.org/2005/Atom') do
        channel do
          xml['atom'].link('href' => href, 'rel' => 'self', 'type' => 'application/rss+xml')
          title feed.xpath('/rss/channel/title').text
          link feed.xpath('/rss/channel/link').text
          description feed.xpath('/rss/channel/description').text
          feed.xpath('/rss/channel/item').each do |post|
            item {
              title post.xpath('./title').text
              pubDate DateTime.parse(post.xpath('./pubDate').text).strftime('%a, %d %b %Y %H:%M:%S %z')
              orig_link = post.xpath('./link').text
              link entry_href % [orig_link.split('/').pop]
              description post.xpath('./description').text
              guid(OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), DIGEST_KEY, orig_link), 'isPermaLink' => 'false')
            }
          end
        end
      end
    end
  end

  get '/entry' do
    href = "http://www.trailjournals.com/journal/entry/#{params['id']}"
    entry = Nokogiri::HTML(open(href))

    hiker_id = params['hiker_id']
    if hiker_id.nil?
      hiker_id = entry.css('a[href*=rss]').attr('href').value.split('/')[-2]
    end


    title = entry.css('.journal-title').first.text.gsub(/^TrailJournals.com\W+/, '')
    date = entry.css('.entry-date').first.text.strip rescue nil
    stats = entry.css('.panel-heading .row:nth-child(n+2) span').to_a rescue []
    stats.map! do |stat|
      stat.text.strip;
    end
    img_href = entry.css('.entry img').first.attr('src') rescue nil
    blockquote = entry.css('.entry')
    signature = blockquote.css('.journal-signature').text.strip
    body = ''

    if blockquote
      blockquote.children.each do |node|
        if ['text', 'p', 'h4'].include?(node.name)
          text = node.text.strip
          body += "<p>#{text}</p>" if text.length > 0
        end
      end
    end

    styles = '
      body {
        font-family: "Verdana";
        font-size: 15pt;
        display: flex;
        justify-content: center;
      }
      body.light {
        background-color: #f8f7f5;
        color: #494949;
      }
      body.dark {
        background-color: #494949;
        color: #f8f7f5;
      }
      body.dark a {
        color: #798def;
      }
      article {
        max-width: 700px;
      }
      p {
        line-height: 27pt;
      }
      header th {
        text-align: left;
      }
      .entry-content-asset {
        float: left;
        margin-right: 25px;
        margin-top: 1.5em;
      }
      .published {
        display: flex;
      }
      .published time {
        flex-grow: 1;
        font-style: italic;
      }
      .theme {
        align-self: flex-end;
        flex-grow: 0;
      }
      .theme > span {
        display: inline-block;
        height: 1em;
        width: 1em;
        border: 1px solid #999999;
        margin: 3px 0 5px 1em;
        border-radius: 15px;
        cursor: pointer;
      }
      .theme .selected {
        cursor: auto;
      }
      .theme .light {
        background-color: #f8f7f5;
      }
      .theme .dark {
        background-color: #494949;
      }
      .light.selected {
        box-shadow: 0px 0px 12px #666;
      }
      .dark.selected {
        box-shadow: 0px 0px 12px #aaa;
      }
      .icon {
        vertical-align: middle;
      }
      .signature {
        font-style: italic;
        color: grey;
        display: flex;
        flex-direction: row;
      }
      .signature em {
        display: flex;
        align-items: center;
        width: 100%;
      }
      .signature em a:first-child {
        flex-basis: 70px;
      }
      .nav {
        margin-bottom: 2em;
      }
      .nav a + a {
        margin-left: .5em;
      }
    '

    theme = request.cookies['theme'] || 'light';
    light_selected = theme == 'light' ? 'selected' : ''
    dark_selected = theme == 'dark' ? 'selected' : ''
    response = "<!DOCTYPE html>"
    response += "<html lang='en'><head><title>#{title}</title><style type='text/css'>#{styles}</style>"
    response += "<script src='https://cdnjs.cloudflare.com/ajax/libs/fetch/2.0.3/fetch.min.js'></script>"
    response += "</head><body class='#{theme}'><article class='hentry'><header><h1 class='entry-title'>#{title}</h1>"
    response += "<p class='published'>"
    response += "<time datetime='#{Date.parse(date)}'>#{date}</time>" if date
    response += "<span class='theme'><span class='light #{light_selected}'></span><span class='dark #{dark_selected}'></span></span></p>"
    response += '<table>'
    stats.each_index do |i|
      response += "<tr><th>#{stats[i]}</th><td>#{stats[i + 1]}</td></tr>" if stats[i] =~ /:/ && stats[i + 1] !~ /:/
    end
    response += '</table></header>'
    response += "<img src='http://www.trailjournals.com#{img_href}' alt='photo' class='entry-content-asset'/>" if img_href
    response += "<div class='entry-content'>#{body}</div>" if body
    response += "<footer><p class='signature'><em>"
    response += "<a href='#{request.scheme}://#{request.host}:#{request.port}/hiker?id=#{hiker_id}'><img class='icon' src='/rss.svg' alt='rss icon' width=48 height=48></a> " if hiker_id
    response += "<a href='http://www.trailjournals.com/journal/about/#{hiker_id}'>" if hiker_id
    response += "#{signature}" if signature
    response += '</a>' if hiker_id
    response += '</em></p></footer>'
    response += '<div class="nav"></div></article><script src="/nav.js"></script></body></html>'
    erb response
  end

  get '/proxy' do
    href = "http://www.trailjournals.com/entry.cfm?id=#{params['id']}"
    erb open(href).read
  end
end
