FROM maven AS build-env
WORKDIR /app
COPY . .
RUN mvn -Pdistribution -pl distribution/server-dist -am -Dmaven.test.skip clean install
WORKDIR /output
RUN tar xfz /app/distribution/server-dist/target/keycloak-*.tar.gz

FROM registry.access.redhat.com/ubi8-minimal

ENV KEYCLOAK_VERSION 8.0.0
ENV JDBC_POSTGRES_VERSION 42.2.5
ENV JDBC_MYSQL_VERSION 8.0.19
ENV JDBC_MARIADB_VERSION 2.5.4
ENV JDBC_MSSQL_VERSION 7.4.1.jre11

ENV LAUNCH_JBOSS_IN_BACKGROUND 1
ENV PROXY_ADDRESS_FORWARDING false
ENV JBOSS_HOME /opt/jboss/keycloak
ENV LANG en_US.UTF-8

USER root
RUN microdnf update -y && microdnf install -y glibc-langpack-en gzip hostname java-11-openjdk-headless openssl tar which && microdnf clean all

COPY --from=build-env /output/keycloak-* /opt/jboss/keycloak
ADD build-tools /opt/jboss/tools
RUN /opt/jboss/tools/build-keycloak.sh

USER 1000

EXPOSE 8080
EXPOSE 8443

ENTRYPOINT [ "/opt/jboss/tools/docker-entrypoint.sh" ]

CMD ["-b", "0.0.0.0"]