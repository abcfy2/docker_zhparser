# vim:set ft=dockerfile:
FROM postgres:9.6-alpine

RUN set -ex \
    \
    && wget -qO- "http://www.xunsearch.com/scws/down/scws-1.2.3.tar.bz2" | tar xjf - \
    && wget -O- "https://github.com/amutu/zhparser/archive/master.tar.gz" | tar xzf - \
    \
    && apk add --no-cache --virtual .build-deps \
        gcc \
        libc-dev \
        make \
        pkgconf \
    && cd /scws-1.2.3 \
    && ./configure \
    && make -j$(nproc) install V=0 \
    && cd /zhparser-master \
    && make install \
    && apk del .build-deps \
    && rm -rf /zhparser-master /scws-1.2.3

RUN echo -e "CREATE EXTENSION IF NOT EXISTS pg_trgm;\n\
CREATE EXTENSION IF NOT EXISTS zhparser;\n\
DO\n\
\$\$BEGIN\n\
    CREATE TEXT SEARCH CONFIGURATION chinese_zh (PARSER = zhparser);\n\
    ALTER TEXT SEARCH CONFIGURATION chinese_zh ADD MAPPING FOR n,v,a,i,e,l,t WITH simple;\n\
EXCEPTION\n\
   WHEN unique_violation THEN\n\
      NULL;  -- ignore error\n\
END;\$\$;\n\
" > /docker-entrypoint-initdb.d/init-zhparser.sql
