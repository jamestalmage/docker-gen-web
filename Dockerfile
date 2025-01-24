FROM nginxproxy/docker-gen:latest
LABEL maintainer="james.talmage@jrtechnical.com"
ENV WEBPROC_VERSION=0.4.0
ARG TARGETPLATFORM
RUN case ${TARGETPLATFORM} in \
         "linux/amd64")  WEBPROC_ARCH=amd64  ;; \
         "linux/arm64")  WEBPROC_ARCH=arm64  ;; \
         "linux/arm/v7") WEBPROC_ARCH=armv7  ;; \
         "linux/arm/v6") WEBPROC_ARCH=armv6  ;; \
         "linux/386")    WEBPROC_ARCH=386   ;; \
    esac \
    && WEBPROC_URL=https://github.com/jpillora/webproc/releases/download/v${WEBPROC_VERSION}/webproc_${WEBPROC_VERSION}_linux_${WEBPROC_ARCH}.gz \
    && apk update \
    && apk --nocache add --virtual .build-deps curl \
    && curl -sL $WEBPROC_URL | gzip -d - > /usr/local/bin/webproc \
    && chmod +x /usr/local/bin/webproc \
    && apk del .build-deps

RUN mkdir -p /etc/templates
RUN mkdir -p /etc/output

COPY <<EOT /etc/docker-gen.conf
[[config]]
template = "/etc/templates/helloworld.tmpl"
dest = "/etc/output/helloworld"
EOT

COPY <<EOT /etc/templates/helloworld.tmpl
#hello world
{{ json . }}
EOT

COPY <<"EOT" /app/entry-wrapper.sh
#!/bin/sh
echo "***Regenerating Output***"
/app/docker-entrypoint.sh $@
cat /etc/output/helloworld
EOT

RUN chmod +x /app/entry-wrapper.sh

ENTRYPOINT ["webproc", \
    "-c", "/etc/templates/helloworld.tmpl", \
    "-c", "/etc/docker-gen.conf", \
    "-c", "/etc/output/helloworld", \
    "--", "/app/entry-wrapper.sh", "-config", "/etc/docker-gen.conf"]