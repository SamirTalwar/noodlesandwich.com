FROM nginx

COPY src/nginx.conf.template /etc/nginx/conf.d/default.conf.template
COPY build /usr/share/nginx/html
RUN chmod -R go=u-w /usr/share/nginx/html
CMD set -ex; \
    envsubst '$PORT' \
      < /etc/nginx/conf.d/default.conf.template \
      > /etc/nginx/conf.d/default.conf; \
    exec nginx -g 'daemon off;'
