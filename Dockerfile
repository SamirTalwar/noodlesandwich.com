FROM node:stretch

ENV TINI_VERSION v0.16.1
RUN set -ex; \
    curl -fsSL -o /usr/local/bin/tini https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini; \
    chmod +x /usr/local/bin/tini

RUN yarn global add dathttpd

ARG SITE_HOST
ENV SITE_HOST $SITE_HOST
ARG SITE_URL
ENV SITE_URL $SITE_URL

ENTRYPOINT ["/usr/local/bin/tini", "--"]
CMD ["bash", \
     "-c", \
     "echo \"ports:\n  http: ${PORT}\n\nsites:\n  ${SITE_HOST}:\n    url: ${SITE_URL}\" > ~/.dathttpd.yml \
      && exec dathttpd"]
