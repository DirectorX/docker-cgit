FROM alpine:3.15

# Install packages
RUN apk update && apk add \
		runit \
		git \
		cgit \
		nginx \
		markdown \
		highlight \
		fcgiwrap \
		spawn-fcgi \
		py3-markdown \
		py3-pygments

# Copy configuration
COPY config/nginx.conf /etc/nginx/http.d/git.conf
COPY config/cgitrc /etc/cgitrc

# Enable configuration
RUN rm -f /etc/nginx/http.d/default.conf
RUN mkdir -p /run/nginx

# Copy script
COPY script/init.sh /bin/init.sh
COPY script/cgit-fcgiwrap.sh /bin/cgit-fcgiwrap
RUN chmod +x /bin/init.sh && chmod +x /bin/cgit-fcgiwrap
ADD script/runit /etc/sv
RUN chmod +x /etc/sv/*/*

# Syntax highlighting
COPY assets/syntax.css /opt/syntax.css
COPY script/syntax-highlighting.sh /usr/lib/cgit/filters/syntax-highlighting.sh
RUN chmod 777 /usr/lib/cgit/filters/syntax-highlighting.sh
RUN cat /opt/syntax.css >> /usr/share/webapps/cgit/cgit.css
RUN rm /opt/syntax.css

# About fillter
COPY script/about-formatting.sh /usr/lib/cgit/filters/about-formatting.sh
RUN chmod 777 /usr/lib/cgit/filters/about-formatting.sh

# Server
EXPOSE 8080

ENTRYPOINT ["init.sh"]