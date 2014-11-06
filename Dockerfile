FROM bartt/ruby:2.1.3
MAINTAINER Bart Teeuwisse <bart@thecodemill.biz>

RUN cd / && \
    git clone https://github.com/bartt/trailjournals.git && \
    cd /trailjournals && bundle

VOLUME /trailjournals
WORKDIR /trailjournals


ENV TRAILJOURNALS_PORT 9292
EXPOSE $BOOKCASTER_PORT

CMD ["rackup", "--env", "production", "--port", $BOOKCASTER_PORT]
