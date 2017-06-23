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

RUN git clone -b master https://github.com/f9teams/zm-build.git /tmp/zm-build

COPY ./config.build /tmp/zm-build/config.build
RUN cd /tmp/zm-build && ./build.pl
COPY ./healthcheck.py ./healthcheck.py
