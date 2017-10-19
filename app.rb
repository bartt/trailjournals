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

  get '/' do
    current_year = Date.today.year
    erb :index, :locals => {
      :theme => request.cookies['theme'] || 'light',
      :title => 'Trailjournals',
      :trails => [
        {:abbr => 'AT', :path => 'appalachian_trail'},
        {:abbr => 'CDT', :path => 'continental_divide_trail'},
        {:abbr => 'PCT', :path => 'pacific_crest_trail'}
      ],
      :years => (current_year-4..current_year)
    }
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

    title = entry.css('.journal-title').first.text.gsub(/(\d{4})/, '\1 ')
    entry_title = entry.css('.entry-title')
    date = entry.css('.entry-date').first.text.strip rescue nil
    stats = entry.css('.panel-heading .row:nth-child(n+2) span').to_a rescue []
    stats.map! do |stat|
      stat.text.strip
    end
    img_href = entry.css('.entry img').first.attr('src') rescue nil
    avatar_href = entry.css('.journal-thumbnail img').first.attr('src') rescue nil
    blockquote = entry.css('.entry')
    signature = blockquote.css('.journal-signature').text.strip
    body = ''

    if blockquote
      blockquote.children.each do |node|
        if ['text', 'p', 'h4'].include?(node.name)
          text = node.text.strip
          body += "<p>#{text}</p>" if text.length > 0 && text !~ /^\W+$/
          img = node.css('img').first rescue nil
          if img then
            img['class'] = 'entry-content-asset'
            body += img.to_html
          end
        end
      end
    end

    erb :entry, :locals => {
      :theme => request.cookies['theme'] || 'light',
      :title => title,
      :entry_title => entry_title,
      :date => date,
      :hiker_id => hiker_id,
      :avatar_href => avatar_href,
      :stats => stats,
      :img_href => img_href,
      :body => body,
      :signature => signature,
      :request => request
    }
  end

  get '/proxy' do
    href = "http://www.trailjournals.com/entry.cfm?id=#{params['id']}"
    erb open(href).read, :layout => false
  end

  # Prevent 404 errors for the images in proxied trailjournals.com pages.
  get '/images/*' do
    200 # HTTP_OK
  end
end
