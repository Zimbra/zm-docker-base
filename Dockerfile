FROM maven:3.5-jdk-8-alpine

ENV PACKAGES="\
  curl \
  gettext \
  dumb-init \
  musl \
  linux-headers \
  build-base \
  bash \
  bash-completion \
  shadow \
  git \
  ca-certificates \
  python2 \
  python2-dev \
  py-setuptools \
  vim \
  wget \
  # install zimbra pre-requisites
  # ant \
  # ant-contrib \
  alpine-sdk \
  git \
  # maven \
  net-tools \
  # nodejs \
  nodejs-npm \
  # openjdk-8-jdk \
  ruby \
  rsyslog \
  util-linux \
"

RUN apk update

RUN apk add openjdk8 --update-cache --repository http://dl-4.alpinelinux.org/alpine/edge/community/ --allow-untrusted
RUN apk add apache-ant --update-cache --repository http://dl-4.alpinelinux.org/alpine/edge/testing/ --allow-untrusted
RUN echo \
  # replacing default repositories with edge ones
  && echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" > /etc/apk/repositories \
  && echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
  && echo "http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories \
  && apk add --no-cache $PACKAGES || \
    (sed -i -e 's/dl-cdn/dl-4/g' /etc/apk/repositories && apk add --no-cache $PACKAGES) \
  && echo "http://dl-cdn.alpinelinux.org/alpine/v$ALPINE_VERSION/main/" > /etc/apk/repositories \
  # make some useful symlinks that are expected to exist
  && if [[ ! -e /usr/bin/python ]];        then ln -sf /usr/bin/python2.7 /usr/bin/python; fi \
  && if [[ ! -e /usr/bin/python-config ]]; then ln -sf /usr/bin/python2.7-config /usr/bin/python-config; fi \
  && if [[ ! -e /usr/bin/easy_install ]];  then ln -sf /usr/bin/easy_install-2.7 /usr/bin/easy_install; fi \

  # Install and upgrade Pip
  && easy_install pip \
  && pip install --upgrade pip \
  # Install flask for healthcheck
  && pip install flask flask_api \
  && if [[ ! -e /usr/bin/pip ]]; then ln -sf /usr/bin/pip2.7 /usr/bin/pip; fi \
  && echo

WORKDIR /opt/zimbra

RUN npm install -g n && \
    n latest && \
    npm install -g junit-merge
RUN bash
RUN addgroup -S zimbra && \
    adduser -S -g zimbra zimbra && \
    # bash && \
    # chsh -s /bin/bash zimbra && \
    chown zimbra:zimbra /opt/zimbra && \
    usermod -d /opt/zimbra zimbra && \
    # Trick build into skipping resolvconf as docker overrides for DNS
    # echo "resolvconf resolvconf/linkify-resolvconf boolean false" # | debconf-set-selections
    echo "resolvconf man"
    #resolvconf resolvconf/linkify-resolvconf

RUN mkdir -p /zimbra/release && \
    curl 'https://files.zimbra.com/downloads/8.7.11_GA/zcs-8.7.11_GA_1854.UBUNTU16_64.20170531151956.tgz' \
    -H 'Accept-Encoding: gzip, deflate, br' \
    -H 'Accept-Language: en-US,en;q=0.8' \
    -H 'Upgrade-Insecure-Requests: 1' \
    -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Safari/537.36' \
    -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8' \
    -H 'Referer: https://www.zimbra.com/downloads/zimbra-collaboration-open-source/' \
    -H 'Connection: keep-alive' \
    --compressed -o /tmp/release-zimbra-8.tgz && \
    tar xzvf /tmp/release-zimbra-8.tgz -C /zimbra/release --strip-components=1

COPY ./healthcheck.py /zimbra/healthcheck.py
