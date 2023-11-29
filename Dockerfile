FROM node:lts-alpine
LABEL author="Bart Teeuwisse <bart@thecodemill.biz>"

RUN mkdir /trailjournals
COPY package.json package-lock.json index.js /trailjournals/
COPY views/ /trailjournals/views/
COPY public/ /trailjournals/public/

RUN cd /trailjournals && \
  npm install -g npm@10.2.4 && \
  npm install --omit dev --omit optional --omit peer  

WORKDIR /trailjournals

EXPOSE 9292
USER nobody

CMD ["node", "index.js"]
