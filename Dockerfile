FROM ruby:2.2.5-slim

MAINTAINER Thilo-Alexander Ginkel <tg@tgbyte.de>

EXPOSE 10000 35729
ENV RACK_ENV=production \
    RUN_AS=${UID:-www} \
    DUMBINIT_VERSION=1.0.2 \
    DEBIAN_FRONTEND=noninteractive \
    JAVA_U=92 \
    JAVA_B=14 \
    FOPUB_DIR=/opt/asciidoctor-fopub \
    PATH=/usr/local/bundle/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/jdk1.8.0/bin:/opt/asciidoctor-fopub/bin \
    GRADLE_USER_HOME=/opt/gradle

RUN set -x \
    && mkdir -p /home/slides \
    && apt-get update \
    && apt-get install -y -o Apt::Install-Recommends=0 \
       ca-certificates \
       git \
       wget \
       xsltproc \
    && wget -q -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v${DUMBINIT_VERSION}/dumb-init_${DUMBINIT_VERSION}_amd64 \
    && chmod +x /usr/local/bin/dumb-init \
    && wget -q -O - --no-cookies --header 'Cookie: gpw_e24=x; oraclelicense=accept-securebackup-cookie' \
       http://download.oracle.com/otn-pub/java/jdk/8u${JAVA_U}-b${JAVA_B}/server-jre-8u${JAVA_U}-linux-x64.tar.gz | \
       tar xvz -C /opt \
    && chown -R root:root /opt/jdk1.8.0_${JAVA_U} \
    && ln -s /opt/jdk1.8.0_${JAVA_U} /opt/jdk1.8.0 \
    && (cd /opt && git clone https://github.com/asciidoctor/asciidoctor-fopub && "${FOPUB_DIR}/gradlew" -p "$FOPUB_DIR" -q -u installApp) \
    && apt-get remove -y --purge \
       ca-certificates \
       git \
       wget \
    && adduser --uid 500 --disabled-password --gecos "www" --quiet www

COPY Gemfile /home/slides/
COPY Gemfile.lock /home/slides/
WORKDIR /home/slides

RUN set -x \
    && apt-get install -y -o Apt::Install-Recommends=0 \
       build-essential \
       ca-certificates \
       git \
       libssl-dev \
       python-pygments \
    && bundle -j4 --without development test \
    && apt-get remove -y --purge \
       build-essential \
       ca-certificates \
       git \
       libssl-dev \
    && apt-get autoremove -y --purge

ADD . /home/slides
RUN set -x \
    && xsltproc --output /home/slides/docbook-xsl-custom/handout-titlepage.xsl "${FOPUB_DIR}/build/fopub/docbook/template/titlepage.xsl" /home/slides/docbook-xsl-custom/handout-titlepage.xml \
    && mv /home/slides/handouts /usr/local/bin \
    && chmod +x /usr/local/bin/handouts \
    && mkdir -p /home/slides/slides \
    && chown -R www.www /home/slides/slides

USER www

ENTRYPOINT ["/usr/local/bin/dumb-init"]
CMD ["reveal-ck", "serve"]

ONBUILD ARG UID
ONBUILD ENV RUN_AS=${UID:-www}
ONBUILD USER root
ONBUILD ADD . /home/slides
ONBUILD RUN reveal-ck generate && \
            chown -R $RUN_AS /home/slides
ONBUILD USER $RUN_AS
