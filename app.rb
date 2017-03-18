require 'sinatra/base'
require 'nokogiri'
require 'open-uri'
require 'digest/hmac'
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
              guid(Digest::HMAC.hexdigest(orig_link.to_s, DIGEST_KEY, Digest::SHA1), 'isPermaLink' => 'false')
            }
          end
        end
      end
    end
  end

  get '/hiker', :provides => %w(rss atom xml) do

    url = params['id'] ? "http://www.trailjournals.com/rss/index.cfm?jid=#{params['id']}" : params['url']
    feed = Nokogiri::XML(open(url))
    hiker_id = url.split('=').pop
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
              print_link = entry_href % [orig_link.split('=').pop]
              link print_link
              description post.xpath('./description').text
              guid(Digest::HMAC.hexdigest(orig_link, DIGEST_KEY, Digest::SHA1), 'isPermaLink' => 'false')
            }
          end
        end
      end
    end
  end

  get '/entry' do
    href = "http://www.trailjournals.com/journal_print.cfm?autonumber=#{params['id']}"
    hiker_id = params['hiker_id']

    if hiker_id.nil?
      html_entry = Nokogiri::HTML(open("http://www.trailjournals.com/entry.cfm?id=#{params['id']}"))
      hiker_id = html_entry.css('a[href*=rss]').attr('href').value.split('=').pop
    end

    entry = Nokogiri::HTML(open(href))

    title = entry.css('title').first.text.gsub(/^TrailJournals.com\W+/, '')
    date = entry.css('table table tr').first.text.strip rescue nil
    stats = entry.css('table table tr:nth-child(2)').first.text.gsub(/^\W+/, '').strip.split("\r\n") rescue []
    img_href = entry.css('table img').first.attr('src') rescue nil
    blockquote = entry.css('table blockquote').first
    signature = blockquote.css('table').text.strip
    body = ''

    if blockquote
      blockquote.children.each do |node|
        if ['text', 'p'].include?(node.name)
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
      article {
        max-width: 700px;
      }
      p {
        line-height: 27pt;
      }
      .entry-content-asset {
        float: left;
        margin-right: 25px;
      }
      .icon {
        vertical-align: middle;
      }
      .signature {
        font-style: italic;
        color: grey;
      }
      .nav {
        margin-bottom: 2em;
      }
      .nav a + a {
        margin-left: .5em;
      }
    '

    response = "<html><head><title>#{title}</title><style type='text/css'>#{styles}</style>"
    response +="<script src='https://cdnjs.cloudflare.com/ajax/libs/fetch/2.0.3/fetch.min.js'></script>"
    response +="</head><body><article class='hentry'><header><h1 class='entry-title'>#{title}</h1>"
    response += "<p class='published' datetime='#{Date.parse(date)}'><em>#{date}</em></p>" if date
    response += '<table>'
    stats.each_index do |i|
      response += "<tr><th align='left'>#{stats[i]}</th><td>#{stats[i + 1]}</td></tr>" if stats[i] =~ /:/ && stats[i + 1] !~ /:/
    end
    response += '</table></header>'
    response += "<section class='image entry-content-asset'><p><img src='#{img_href}'/></p></section>" if img_href
    response += "<section class='entry-content'>#{body}</section>" if body
    response += "<footer><p class='signature'><em>"
    response += "<a href='#{request.scheme}://#{request.host}:#{request.port}/hiker?id=#{hiker_id}'><img class='icon' src='/rss.gif' width=48 hight=17></a> " if hiker_id
    response += "<a href='http://www.trailjournals.com/about.cfm?trailname=#{hiker_id}'>" if hiker_id
    response += "#{signature}" if signature
    response += '</a>' if hiker_id
    response += '</em></p></footer>'
    response += '<div class="nav"></div></article></body>'
    response += '<script src="/nav.js"></script></html>'
    erb response
  end

  get '/proxy' do
    href = "http://www.trailjournals.com/entry.cfm?id=#{params['id']}"
    erb open(href).read
  end
end
