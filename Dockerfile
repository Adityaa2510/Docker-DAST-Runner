
FROM ghcr.io/zaproxy/zaproxy:stable

USER root

COPY dast-entrypoint.sh /usr/local/bin/dast-entrypoint.sh

RUN chmod +x /usr/local/bin/dast-entrypoint.sh

WORKDIR /zap/wrk

ENTRYPOINT ["/usr/local/bin/dast-entrypoint.sh"]