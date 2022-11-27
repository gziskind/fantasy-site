FROM ruby:2.4.5

ADD . /fantasy_site
WORKDIR /fantasy_site
RUN bundle install

EXPOSE 8080

CMD ["/fantasy_site/bin/server"]