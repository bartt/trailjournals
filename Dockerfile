FROM library/ruby:2-alpine
LABEL author="Bart Teeuwisse <bart@thecodemill.biz>"

RUN apk add --no-cache git build-base libxml2-dev libxslt-dev && \
  mkdir /trailjournals
COPY Gemfile app.rb config.ru /trailjournals/
COPY views/ /trailjournals/views/
COPY public/ /trailjournals/public/

RUN cd /trailjournals && \
  gem install bundler && \
  bundle config build.nokogiri --use-system-libraries && \
  bundle config set --local without 'development' && \
  bundle install && \
  apk del git build-base libxml2-dev libxslt-dev

VOLUME /trailjournals
WORKDIR /trailjournals

EXPOSE 9292
USER nobody

CMD ["bundler", "exec", "rackup", "--env", "production"]
