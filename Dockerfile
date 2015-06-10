FROM bartt/ruby:2.1.3
MAINTAINER Bart Teeuwisse <bart@thecodemill.biz>

RUN cd / && \
  git clone https://github.com/bartt/trailjournals.git && \
  cd /trailjournals && bundle

VOLUME /trailjournals
WORKDIR /trailjournals

EXPOSE 9292
USER nobody

CMD ["rackup", "--env", "production"]
