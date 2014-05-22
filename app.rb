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

    nokogiri do |xml|
      xml.rss('version' => '2.0', 'xmlns:atom' => 'http://www.w3.org/2005/Atom') do
        channel do
          xml['atom'].link('href' => href, 'rel' => 'self', 'type' => 'application/rss+xml')
          title feed.xpath('/rss/channel/title').text
          link feed.xpath('/rss/channel/link').text
          description 'Lastest PCT posts on trailjournals.com'
          feed.xpath('/rss/channel/item[contains(.,"Pacific")]').each do |post|
            item {
              title post.xpath('./title').text
              pubDate DateTime.parse(post.xpath('./pubDate').text).strftime('%a, %d %b %Y %H:%M:%S %z')
              print_link = "http://www.trailjournals.com/journal_print.cfm?autonumber=#{post.xpath('./link').text.split('=').pop}"
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
              print_link = "http://www.trailjournals.com/journal_print.cfm?autonumber=#{post.xpath('./link').text.split('=').pop}"
              link print_link
              description post.xpath('./description').text
              guid(Digest::HMAC.hexdigest(print_link, DIGEST_KEY, Digest::SHA1), 'isPermaLink' => 'false')
            }
          end
        end
      end
    end
  end
end

