#!/bin/sh
set -x

export JAVA_HOME=/opt/jre1.8.0_60/bin
export PATH=$PATH:$JAVA_HOME

sed -i "s/^-Xmx.*$/-Xmx$JETTY_MAX_HEAP/g" /opt/shib-jetty-base/start.ini

/etc/init.d/jetty run
