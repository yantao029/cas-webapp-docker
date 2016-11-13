FROM centos:centos7

MAINTAINER Apereo Foundation

ENV PATH=$PATH:$JRE_HOME/bin

RUN yum -y install wget tar git-all \
    && yum -y clean all

RUN set -x; \
    java_version=8u112; \
    java_bnumber=15; \
    java_semver=1.8.0_112; \
    java_hash=eb51dc02c1607be94249dc28b0223be3712b618ef72f48d3e2bfd2645db8b91a; \

# Download Java, verify the hash, and install \
    cd / \
    && wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" \
    http://download.oracle.com/otn-pub/java/jdk/$java_version-b$java_bnumber/server-jre-$java_version-linux-x64.tar.gz \
    && echo "$java_hash  server-jre-$java_version-linux-x64.tar.gz" | sha256sum -c - \
    && tar -zxvf server-jre-$java_version-linux-x64.tar.gz -C /opt \
    && rm server-jre-$java_version-linux-x64.tar.gz \
    && ln -s /opt/jdk$java_semver/ /opt/jre-home;

# Download the CAS overlay project \
RUN cd / \
    && git clone -b 4.2 --single-branch https://github.com/apereo/cas-overlay-template.git cas-overlay \
    && mkdir /etc/cas \
    && mkdir /etc/cas/jetty \
    && mkdir -p cas-overlay/bin \
    && mkdir -p cas-overlay/src/main/webapp \
    && cp cas-overlay/etc/*.* /etc/cas;

COPY src/main/webapp/ cas-overlay/src/main/webapp/
COPY thekeystore /etc/cas/jetty/
COPY bin/*.* cas-overlay/bin/

RUN chmod -R 750 cas-overlay/bin \
    && chmod 750 cas-overlay/mvnw \
    && chmod 750 /opt/jre-home/bin/java \
	&& chmod 750 /opt/jre-home/jre/bin/java;

EXPOSE 8080 8443

WORKDIR /cas-overlay

ENV JAVA_HOME /opt/jre-home
ENV PATH $PATH:$JAVA_HOME/bin:.

RUN ./mvnw clean package

CMD ["/cas-overlay/bin/run-jetty.sh"]