# syntax=docker/dockerfile:1
FROM ruby:2.7.7

RUN apt-get update && apt-get install -y build-essential npm

WORKDIR /myapp

COPY . /myapp

RUN bundle update --bundler
RUN npm install

ENV RAILS_ENV development

# Add a script to be executed every time the container starts.
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]

