# Azurewind's PostgreSQL image with Chinese full text search
# build: docker build --force-rm -t chenxinaz/zhparser .
# run: docker run --name PostgreSQLcnFt -p 5432:5432 chenxinaz/zhparser
# run interactive: winpty docker run -it --name PostgreSQLcnFt -p 5432:5432 chenxinaz/zhparser --entrypoint bash chenxinaz/zhparser

FROM postgres

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
      gcc \
      make \
      postgresql-server-dev-$PG_MAJOR \
      libc-dev \
      curl \
      bzip2 \
  && rm -rf /var/lib/apt/lists/* \
  && curl -sSkLf "http://www.xunsearch.com/scws/down/scws-1.2.3.tar.bz2" | tar xjf - \
  && curl -sSkLf "https://github.com/amutu/zhparser/archive/master.tar.gz" | tar xzf - \
  && cd scws-1.2.3 \
  && ./configure \
  && make -j$(nproc) install V=0 \
  && cd /zhparser-master \
  && make -j$(nproc) install \
  && apt-get purge -y gcc make libc-dev postgresql-server-dev-$PG_MAJOR curl bzip2 \
  && apt-get autoremove --purge -y \
  && rm -rf /zhparser-master /scws-1.2.3

# pg_trgm is recommend but not required.
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
