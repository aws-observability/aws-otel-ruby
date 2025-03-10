FROM ruby:2.7

WORKDIR /app

COPY . /app

RUN bundle install

ENV HOME=/

ENV RACK_ENV=production

# DO NOT follow this pattern of committing your master key into source code.
# This is just required to run a `production` rails app.

ENV RAILS_MASTER_KEY=e6780fe49c28c60ed2b594459981580c

CMD rails server
