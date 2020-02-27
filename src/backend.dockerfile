FROM alpine:3.8

# Update packages to latest versions
RUN apk update && apk upgrade

# Install latest Python 3
RUN apk add --no-cache python3

# Install pip & cleanup afterwards
RUN python3 -m ensurepip
RUN rm -r /usr/lib/python*/ensurepip

# Update pip, setuptools & wheel to their latest versions
RUN pip3 install --upgrade pip setuptools wheel

# dumps log directly to stream instead of memory buffering
ENV PYTHONUNBUFFERED 1

# Creating working directory
RUN mkdir -p /opt/src
WORKDIR /opt/src

# Copying requirements
COPY ./ .

# Install python package build dependencies
RUN apk add --no-cache --virtual .build-deps \
ca-certificates gcc linux-headers python3-dev musl-dev \
libffi-dev jpeg-dev zlib-dev \
&& apk add --no-cache mysql-dev \
&& pip3 install -r requirements.txt \
&& find /usr/local \
\( -type d -a -name test -o -name tests \) \
-o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) \
-exec rm -rf '{}' + \
&& runDeps="$( \
scanelf --needed --nobanner --recursive /usr/local \
| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
| sort -u \
| xargs -r apk info --installed \
| sort -u \
)" \
&& apk add --virtual .rundeps $runDeps \
&& apk del .build-deps

COPY ./start-tlookup.sh /opt/
RUN chmod +x /opt/start-tlookup.sh

EXPOSE 5000

CMD /opt/start-tlookup.sh