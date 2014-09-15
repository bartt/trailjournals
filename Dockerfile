FROM ubuntu
MAINTAINER Bart Teeuwisse <bart@thecodemill.biz>

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get -y install make ruby ruby-dev git

RUN mkdir /trailjournals
RUN cd / && git clone https://github.com/bartt/trailjournals.git
RUN gem install bundler
RUN cd /trailjournals && bundle

VOLUME /trailjournals
WORKDIR /trailjournals

EXPOSE 9292

CMD ["rackup"]
