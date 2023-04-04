FROM --platform=linux/amd64 ruby:2.7.2

RUN apt-get update && apt-get install -y \ 
  build-essential

RUN gem install bundler -v 2.1.4

RUN mkdir /app
WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs=6 --retry=5

COPY . .

CMD bundle exec lita start