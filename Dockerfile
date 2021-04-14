FROM library/ruby:2.4.1-alpine
LABEL author="Bart Teeuwisse <bart@thecodemill.biz>"

RUN apk add --no-cache git build-base libxml2-dev libxslt-dev

RUN mkdir /trailjournals
COPY Gemfile Gemfile.lock app.rb config.ru /trailjournals/
COPY views/ /trailjournals/views/
COPY public/ /trailjournals/public/

RUN cd /trailjournals && \
  gem install bundler && \
  bundle config build.nokogiri --use-system-libraries && \
  bundle install --without development

VOLUME /trailjournals
WORKDIR /trailjournals

EXPOSE 9292
USER nobody

CMD ["rackup", "--env", "production"]
