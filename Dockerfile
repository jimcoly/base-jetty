FROM centos:centos7

MAINTAINER John Gasper <jtgasper3@gmail.com>

ENV JRE_HOME=/opt/jre1.8.0_60 \
    JAVA_HOME=/opt/jre1.8.0_60 \
    JETTY_HOME=/opt/jetty \
    JETTY_BASE=/opt/shib-jetty-base\ 
    JETTY_MAX_HEAP=512m \
    PATH=$PATH:$JRE_HOME/bin:/opt/container-scripts

RUN yum -y update \
    && yum -y install wget tar unzip

# Download Java, verify the hash, and install
RUN set -x; \
    java_version=8u60; \
    wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" \
    http://download.oracle.com/otn-pub/java/jdk/$java_version-b27/jre-$java_version-linux-x64.tar.gz \
    && echo "49dadecd043152b3b448288a35a4ee6f3845ce6395734bacc1eae340dff3cbf5  jre-$java_version-linux-x64.tar.gz" | sha256sum -c - \
    && tar -zxvf jre-$java_version-linux-x64.tar.gz -C /opt \
    && rm jre-$java_version-linux-x64.tar.gz

# Download Jetty, verify the hash, and install, initialize a new base
RUN set -x; \
    jetty_version=9.3.3.v20150827; \
    wget -O jetty.zip "https://eclipse.org/downloads/download.php?file=/jetty/$jetty_version/dist/jetty-distribution-$jetty_version.zip&r=1" \
    && echo "2972a728bdfba8b1f32d2b4a109abcd7f0c00263  jetty.zip" | sha1sum -c - \
    && unzip jetty.zip -d /opt \
    && mv /opt/jetty-distribution-$jetty_version /opt/jetty \
    && rm jetty.zip \
    && cp /opt/jetty/bin/jetty.sh /etc/init.d/jetty \
    && mkdir -p /opt/shib-jetty-base/modules \
    && mkdir -p /opt/shib-jetty-base/lib/ext \
    && mkdir -p /opt/shib-jetty-base/resources \
    && cd /opt/shib-jetty-base \
    && touch start.ini \
    && $JRE_HOME/bin/java -jar ../jetty/start.jar --add-to-startd=http,https,deploy,ext,annotations,jstl,logging,setuid \
    && sed -i 's/# jetty.http.port=8080/jetty.http.port=80/g' /opt/shib-jetty-base/start.d/http.ini \
    && sed -i 's/# jetty.ssl.port=8443/jetty.ssl.port=443/g' /opt/shib-jetty-base/start.d/ssl.ini \
    && sed -i 's/<New id="DefaultHandler" class="org.eclipse.jetty.server.handler.DefaultHandler"\/>/<New id="DefaultHandler" class="org.eclipse.jetty.server.handler.DefaultHandler"><Set name="showContexts">false<\/Set><\/New>/g' /opt/jetty/etc/jetty.xml

# Download setuid, verify the hash, and place
RUN set -x; \
    wget https://repo1.maven.org/maven2/org/mortbay/jetty/libsetuid/8.1.9.v20130131/libsetuid-8.1.9.v20130131.so \
    && echo "7286c7cb836126a403eb1c2c792bde9ce6018226  libsetuid-8.1.9.v20130131.so" | sha1sum -c - \
    && mv libsetuid-8.1.9.v20130131.so /opt/shib-jetty-base/lib/ext/

ADD shib-jetty-base/ /opt/shib-jetty-base/

RUN useradd jetty -U -s /bin/false \
    && chown -R jetty:root /opt/jetty \
    && chown -R jetty:root /opt/shib-jetty-base 

ADD container-scripts/ /opt/container-scripts/

## Opening 443 (browser TLS), 8443 (SOAP/mutual TLS auth)... 80 specifically not included.
EXPOSE 443 8443

VOLUME [“/opt/shib-jetty-base/logs“]

CMD ["run-jetty.sh"]
