FROM haproxy:latest

COPY haproxy-minimal.cfg /usr/local/etc/haproxy/haproxy-minimal.cfg
COPY haproxy-qos.cfg.template /usr/local/etc/haproxy/haproxy-qos.cfg.template
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

USER root

RUN apt-get update && \
    apt-get install -y gettext && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER haproxy

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["haproxy", "-f", "/tmp/haproxy.cfg"]
