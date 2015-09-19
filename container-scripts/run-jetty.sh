#!/bin/sh
set -x

export JAVA_HOME=/opt/jre1.8.0_60
export PATH=$PATH:$JAVA_HOME/bin

sed -i "s/^-Xmx.*$/-Xmx$JETTY_MAX_HEAP/g" /opt/shib-jetty-base/start.ini

exec /etc/init.d/jetty run
