FROM library/ruby:2.4.1-alpine
MAINTAINER Bart Teeuwisse <bart@thecodemill.biz>

RUN apk add --no-cache git build-base libxml2-dev

RUN cd / && \
  git clone https://github.com/bartt/trailjournals.git && \
  cd /trailjournals && bundle config build.nokogiri --use-system-libraries && \
  bundle install --without=development

VOLUME /trailjournals
WORKDIR /trailjournals

EXPOSE 9292
USER nobody

CMD ["rackup", "--env", "production"]
