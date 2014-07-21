require 'sinatra/base'
require 'nokogiri'
require 'open-uri'
require 'digest/hmac'
require 'time'

DIGEST_KEY = 'super secret'

class TrailJournals < Sinatra::Base
  get '/pct', :provides => %w(rss atom xml) do

    feed = Nokogiri::XML(open('http://www.trailjournals.com/rss/index.cfm'))
    href = "http://#{request.host}:#{request.port}#{request.path}"
    entry_href = "http://#{request.host}:#{request.port}/entry?id="

    nokogiri do |xml|
      xml.rss('version' => '2.0', 'xmlns:atom' => 'http://www.w3.org/2005/Atom') do
        channel do
          xml['atom'].link('href' => href, 'rel' => 'self', 'type' => 'application/rss+xml')
          title "#{feed.xpath('/rss/channel/title').text} : Pacific Crest Trail"
          link feed.xpath('/rss/channel/link').text
          description 'Lastest PCT posts on trailjournals.com'
          feed.xpath('/rss/channel/item[contains(.,"Pacific")]').each do |post|
            item {
              title post.xpath('./title').text
              pubDate DateTime.parse(post.xpath('./pubDate').text).strftime('%a, %d %b %Y %H:%M:%S %z')
              print_link = entry_href + post.xpath('./link').text.split('=').pop
              link print_link
              description post.xpath('./description').text
              guid(Digest::HMAC.hexdigest(print_link, DIGEST_KEY, Digest::SHA1), 'isPermaLink' => 'false')
            }
          end
        end
      end
    end
  end

  get '/hiker', :provides => %w(rss atom xml) do

    feed = Nokogiri::XML(open(params['url']))
    href = "http://#{request.host}:#{request.port}#{request.path}?url=#{params['url']}"
    entry_href = "http://#{request.host}:#{request.port}/entry?id="

    nokogiri do |xml|
      xml.rss('version' => '2.0', 'xmlns:atom' => 'http://www.w3.org/2005/Atom') do
        channel do
          xml['atom'].link('href' => href, 'rel' => 'self', 'type' => 'application/rss+xml')
          title feed.xpath('/rss/channel/title').text
          link feed.xpath('/rss/channel/link').text
          description 'Lastest PCT posts on trailjournals.com'
          feed.xpath('/rss/channel/item').each do |post|
            item {
              title post.xpath('./title').text
              pubDate DateTime.parse(post.xpath('./pubDate').text).strftime('%a, %d %b %Y %H:%M:%S %z')
              print_link = entry_href + post.xpath('./link').text.split('=').pop
              link print_link
              description post.xpath('./description').text
              guid(Digest::HMAC.hexdigest(print_link, DIGEST_KEY, Digest::SHA1), 'isPermaLink' => 'false')
            }
          end
        end
      end
    end
  end

  get '/entry' do
    href = "http://www.trailjournals.com/journal_print.cfm?autonumber=#{params['id']}"

    entry = Nokogiri::HTML(open(href))

    title = entry.css('title').first.text.gsub(/^TrailJournals.com\W+/, '')
    date = entry.css('table table tr').first.text.strip rescue nil
    stats = entry.css('table table tr:nth-child(2)').first.text.gsub(/^\W+/, '').strip.split("\r\n") rescue []
    img_href = entry.css('table img').first.attr('src') rescue nil
    body = entry.css('table blockquote').first

    if body
      # Remove the image wrapped in a table
      body.first_element_child.remove if img_href

      signature = body.css('table').text.strip

      # Remove signature wrapped in a table
      body.css('table').first.remove
    end

    response = "<html><head><title>#{title}</title></head><body><h1>#{title}</h1>"
    response += "<p>#{date}</p>" if date
    stats.each_index do |i|
      response += "<p>#{stats[i]} #{stats[i + 1]}<p>" if stats[i] =~ /:/ && stats[i + 1] !~ /:/
    end
    response += "<p>""<img src='#{img_href}'/></p>" if img_href
    response += "#{body.inner_html}<p>#{signature}</body></html>" if body
    erb response
  end
end

