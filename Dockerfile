FROM ruby:2.2.5-slim

EXPOSE 10000 35729
ENV RACK_ENV=production

ENV DUMBINIT_VERSION=1.0.2
RUN mkdir -p /home/slides && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y -o Apt::Install-Recommends=0 wget ca-certificates && \
    wget -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v${DUMBINIT_VERSION}/dumb-init_${DUMBINIT_VERSION}_amd64 && \
    chmod +x /usr/local/bin/dumb-init && \
    apt-get remove -y --purge wget ca-certificates && \
    adduser --uid 500 --disabled-password --gecos "www" --quiet www

COPY Gemfile /home/slides/
COPY Gemfile.lock /home/slides/
WORKDIR /home/slides

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y -o Apt::Install-Recommends=0 python-pygments libssl-dev build-essential git ca-certificates && \
    bundle -j4 --without development test && \
    apt-get remove -y --purge build-essential libssl-dev git ca-certificates && \
    apt-get autoremove -y --purge

ADD . /home/slides
RUN mkdir -p /home/slides/slides && \
    chown www.www /home/slides/slides

USER www

ENTRYPOINT ["/usr/local/bin/dumb-init", "reveal-ck"]
CMD ["serve"]

ONBUILD ADD . /home/slides
ONBUILD RUN reveal-ck generate
