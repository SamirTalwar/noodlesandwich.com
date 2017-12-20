FROM nginx

COPY src/nginx.conf /etc/nginx/conf.d/default.conf
COPY build/* /usr/share/nginx/html/
RUN chmod -R go=u-w /usr/share/nginx/html
