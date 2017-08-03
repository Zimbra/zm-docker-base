FROM ubuntu:16.04

RUN apt-get update && \
    apt-get install -y \
    # install basics
    curl \
    gettext \
    python \
    python-pip \
    slay \
    vim \
    wget \
    # install zimbra pre-requisites
    ant \
    ant-contrib \
    build-essential \
    git \
    maven \
    net-tools \
    npm \
    openjdk-8-jdk \
    ruby \
    rsyslog \
    software-properties-common

WORKDIR /opt/zimbra

RUN npm install -g n && \
    n latest && \
    npm install -g junit-merge

# Install flask for healthcheck
RUN pip install --upgrade pip && \
    pip install flask flask_api

RUN groupadd -r zimbra && \
    useradd -r -g zimbra zimbra && \
    chsh -s /bin/bash zimbra && \
    chown zimbra:zimbra /opt/zimbra && \
    usermod -d /opt/zimbra zimbra && \
    # Trick build into skipping resolvconf as docker overrides for DNS
    echo "resolvconf resolvconf/linkify-resolvconf boolean false" | debconf-set-selections

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
    tar xzvf /tmp/release-zimbra-8.tgz -C /zimbra/release --strip-components=1 && \
    rm /tmp/release-zimbra-8.tgz

COPY ./healthcheck.py /zimbra/healthcheck.py
