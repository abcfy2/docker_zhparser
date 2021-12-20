![Docker Build (Debian)](https://github.com/abcfy2/docker_zhparser/actions/workflows/docker_build_debian.yml/badge.svg)
![Docker Build (Alpine)](https://github.com/abcfy2/docker_zhparser/actions/workflows/docker_build_alpine.yml/badge.svg)
[![Docker Pulls](https://img.shields.io/docker/pulls/abcfy2/zhparser)](https://hub.docker.com/r/abcfy2/zhparser)
[![Latest Tag](https://img.shields.io/docker/v/abcfy2/zhparser)](https://hub.docker.com/r/abcfy2/zhparser/tags)

A source repo of Postgres Chinese full-test search docker image, based on zhparser.

Fork from: <https://github.com/chen-xin/docker_zhparser>, and upgrade to new version.

# Supported tags and respective Dockerfile links

- [latest](https://github.com/abcfy2/docker_zhparser/blob/main/Dockerfile.debian)
- [14](https://github.com/abcfy2/docker_zhparser/blob/main/Dockerfile.debian)
- [13](https://github.com/abcfy2/docker_zhparser/blob/main/Dockerfile.debian)
- [12](https://github.com/abcfy2/docker_zhparser/blob/main/Dockerfile.debian)
- [11](https://github.com/abcfy2/docker_zhparser/blob/main/Dockerfile.debian)
- [10](https://github.com/abcfy2/docker_zhparser/blob/main/Dockerfile.debian)
- [9.6](https://github.com/abcfy2/docker_zhparser/blob/main/Dockerfile.debian)
- [alpine](https://github.com/abcfy2/docker_zhparser/blob/main/Dockerfile.alpine)
- [14-alpine](https://github.com/abcfy2/docker_zhparser/blob/main/Dockerfile.alpine)
- [13-alpine](https://github.com/abcfy2/docker_zhparser/blob/main/Dockerfile.alpine)
- [12-alpine](https://github.com/abcfy2/docker_zhparser/blob/main/Dockerfile.alpine)
- [11-alpine](https://github.com/abcfy2/docker_zhparser/blob/main/Dockerfile.alpine)
- [10-alpine](https://github.com/abcfy2/docker_zhparser/blob/main/Dockerfile.alpine)
- [9.6-alpine](https://github.com/abcfy2/docker_zhparser/blob/main/Dockerfile.alpine)

The numbers above are postgres docker image versions.

# Quick reference

Until version 9, Chinese full-text search is not shipped with PostgreSQL official release, and has to be implement by third-party extensions.

Zhparser, based on Xunsearch's Simple Chinese Word Segmentation(SCWS), appears to be most frequent in google results of "Chinese full-text postgres", and still actively mantained recently.

[zhparser](https://github.com/amutu/zhparser "zhparser on Github")
[xunsearch dict attr descriptions](<http://www.xunsearch.com/scws/docs.php#attr>"dict attrs")
[scel2mmseg orginal](<https://github.com/aboutstudy/scel2mmseg>"sougou dict convert to text")

# How to use this image

To run this image, please refer to the [postgres docker image doc](https://store.docker.com/images/postgres).
A basic command would be `docker run -p 5432:5432 chenxinaz/zhparser`.

When the container runs first time, the follow scripts would be executed on the default database. You need to run them to configure zhparser for any other newly created databases :

```sql
CREATE EXTENSION zhparser;
CREATE TEXT SEARCH CONFIGURATION chinese_zh (PARSER = zhparser);
ALTER TEXT SEARCH CONFIGURATION chinese_zh ADD MAPPING FOR n,v,a,i,e,l WITH simple;
```

**config descriptions:**

- "chinese_zh" is a custom name, change to what you like.
- "n,v,a,i,e,l,t" is the token types, unmapped token types would not be used for document tockenize. Use `\dFp+ zhparser` to list all token types zhparser populates.

## Testing

**ts_debug:**

`select ts_debug('chinese_zh', '白垩纪是地球上海陆分布和生物界急剧变化、火山活动频繁的时代');`

```txt
ts_debug
-------------------------------------------
(t,time,白垩纪,{},,)
(v,verb,是,{simple},simple,{是})
(n,noun,地球,{simple},simple,{地球})
(n,noun,上海,{simple},simple,{上海})
(m,numeral,陆,{},,)
(v,verb,分布,{simple},simple,{分布})
(c,conjunction,和,{},,)
(n,noun,生物界,{simple},simple,{生物界})
(d,adverb,急剧,{},,)
(v,verb,变化,{simple},simple,{变化})
(u,auxiliary,、,{},,)
(n,noun,火山,{simple},simple,{火山})
(v,verb,活动,{simple},simple,{活动})
(a,adjective,频繁,{simple},simple,{频繁})
(u,auxiliary,的,{},,)
(n,noun,时代,{simple},simple,{时代})
(16 rows)
```

We can see the parser make some mistakes:"海陆" is not identified as a single word.
Another portential problem is that "白垩纪" was identified as "t,time", which not included in zhparser official document's sample mapping setting(only 'n,v,a,i,e,l' ), this make newbees confused as it is not tokenized.

**to_tsvector:**

`select to_tsvector('chinese_zh', '白垩纪是地球上海陆分布和生物界急剧变化、火山活动频繁的时代');`

```txt
to_tsvector
--------------------------------------------------------------------------------------------
'上海':3 '分布':4 '变化':6 '地球':2 '时代':10 '是':1 '活动':8 '火山':7 '生物界':5 '频繁':9
(1 row)
```

We can see "白垩纪" is not in the result. To include it, we need `ALTER TEXT SEARCH CONFIGURATION chinese_zh ADD MAPPING FOR t WITH simple;`

**to_tsquery & plainto_tsquery**

```sql
select to_tsquery('chinese_zh', '白垩纪是地球上海陆分布和生物界急剧变化、火山活动频繁的时代');
select plainto_tsquery('chinese_zh', '白垩纪是地球上海陆分布和生物界急剧变化、火山活动频繁的时代');
select to_tsquery('chinese_zh', '白垩纪 是地球上海陆分布和生物界急剧变化、火山活动频繁的时代');
select plainto_tsquery('chinese_zh', '白垩纪 是地球上海陆分布和生物界急剧变化、火山活动频繁的时代');
```

```txt
                                       to_tsquery
-----------------------------------------------------------------------------------------
 '是' & '地球' & '上海' & '分布' & '生物界' & '变化' & '火山' & '活动' & '频繁' & '时代'
(1 row)
```

All above querys products same result excepts the 3rd throws _syntax error_. You can try the queries without 'chinese_zh' argument to see what happens.

**combine query & vector**

```sql
select to_tsquery('地球') @@ to_tsvector('chinese_zh', '白垩纪是地球上海陆分布和生物界急剧变化、火山活动频繁的时代');
select to_tsquery('chinese_zh', '地球') @@ to_tsvector('chinese_zh', '白垩纪是地球上海陆分布和生物界急剧变化、火山活动频繁的时代');
```

```txt
?column?
.----------
t
(1 row)
```

```select to_tsquery('地球上') @@ to_tsvector('chinese_zh', '白垩纪是地球上海陆分布和生物界急剧变化、火山活动频繁的时代');
select to_tsquery('chinese_zh', '地球上') @@ to_tsvector('chinese_zh', '白垩纪是地球上海陆分布和生物界急剧变化、火山活动频繁的时代');
```

```txt
>?column?
.----------
f
(1 row)
```

This result is unexpected, even blind can see with his nose that '地球上' is definatly inside '白垩纪是地球上海陆分布..', why false? Let's dive a little deeper:

```sql
select to_tsquery('地球上');
select to_tsquery('chinese_zh', '地球上');
select to_tsvector('白垩纪是地球上海陆分布和生物界急剧变化、火山活动频繁的时代');
select to_tsvector('chinese_zh', '白垩纪是地球上海陆分布和生物界急剧变化、火山活动频繁的时代');
select ts_debug('chinese_zh', '地球上');
select to_tsvector('chinese_zh', '海陆');
```

```txt
'地球上'
'地球' & '上'
'火山活动频繁的时代':2 '白垩纪是地球上海陆分布和生物界急剧变化':1
'上海':3 '分布':4 '变化':6 '地球':2 '时代':10 '是':1 '活动':8 '火山':7 '生物界':5 '频繁':9
 (n,noun,地球,{simple},simple,{地球})
 (v,verb,上,{simple},simple,{上})
'海陆':1
```

Now we can see that the ts_query `'地球' & '上'` would not math the ts_vector `'上海':3 '分布':4 '变化':6 '地球':2 '时代':10 '是':1 '活动':8 '火山':7 '生物界':5 '频繁':9`.

Supposed soluctions are:

- Make '地球上' a token with higher priority than '上海'(bad idea);
- Make '海陆' a token with higher priority than '上海';

1. Use in table and querys

---

_Note_: I have added my custom dict for words '白垩纪' and '达纳苏斯', see next chapter for detail.

```sql
-- you may need run the next line first, I haven't tested yet
-- CREATE EXTENSION pg_trgm;

create table testing(
  title text
  );

insert into testing values('白垩纪是地球上海陆分布和生物界急剧变化、火山活动频繁的时代');
insert into testing values('艾泽拉斯包括卡利姆多、东部王国两大大陆，暗夜精灵主城达纳苏斯位于东部王国北端。');
create index ind_testing on testing using gin (to_tsvector('chinese_zh', title));

select * from testing where to_tsquery('chinese_zh', '白垩纪') @@ to_tsvector('chinese_zh', title);
select * from testing where to_tsquery('chinese_zh', '达纳苏斯') @@ to_tsvector('chinese_zh', title);

explain select * from testing where to_tsquery('chinese_zh', '达纳苏斯') @@ to_tsvector('chinese_zh', title);
```

You may confused why the last statement shows that the query is using sequence scan instead of index scan,
there may be 2 reasons:

1. Query string is too short, that postgres thinks it matches too much rows and not worthy using index;
1. Rows in table is few and hardly benifit from indexing.

In my test of 100,000 rows table, the result is :

```txt
Bitmap Heap Scan on doc_pack  (cost=23.88..1658.13 rows=500 width=1448) (actual time=18.410..18.411 rows=1 loops=1)
  Recheck Cond: ('''达纳苏斯'''::tsquery @@ to_tsvector('chinese_zh'::regconfig, (title)::text))
  Heap Blocks: exact=1
  ->  Bitmap Index Scan on ind_doc_pack_title  (cost=0.00..23.75 rows=500 width=0) (actual time=18.402..18.402 rows=1 loops=1)
        Index Cond: ('''达纳苏斯'''::tsquery @@ to_tsvector('chinese_zh'::regconfig, (title)::text))
Planning time: 0.103 ms
Execution time: 18.440 ms
```

Another test of 2,700,000 rows table, the result is :

```txt
Bitmap Heap Scan on docs  (cost=47.12..11533.37 rows=2983 width=2844) (actual time=25.364..25.365 rows=1 loops=1)
   Recheck Cond: ('''达纳苏斯'''::tsquery @@ to_tsvector('chinese_zh'::regconfig, (title)::text))
   Heap Blocks: exact=1
   ->  Bitmap Index Scan on ind_doc_title  (cost=0.00..46.37 rows=2983 width=0) (actual time=25.355..25.355 rows=1 loops=1)
         Index Cond: ('''达纳苏斯'''::tsquery @@ to_tsvector('chinese_zh'::regconfig, (title)::text))
 Planning time: 19.188 ms
 Execution time: 25.392 ms
```

```sql
insert into doc_pack(id, title, no, doc_keeper, archive_type, speciaty)
values ('asdf', '艾泽拉斯包括卡利姆多、东部王国两大大陆，暗夜精灵主城达纳苏斯位于东部王国北端。', 'b1234', 'aa', 'bb', 'cc');

explain analyze select * from doc_pack where to_tsquery('chinese_zh', '达纳苏斯') @@ to_tsvector('chinese_zh', title);

insert into docs(id, file_type, create_time, title, size, uri)
values ('asdf', 'aaa', now(), '艾泽拉斯包括卡利姆多、东部王国两大大陆，暗夜精灵主城达纳苏斯位于东部王国北端。', 0, '');

explain analyze select * from docs where to_tsquery('chinese_zh', '达纳苏斯') @@ to_tsvector('chinese_zh', title);
```

2. Add customer dicts(txt)

---

First test some custom words with current configure:

```sql
select ts_debug('chinese_zh', '艾泽拉斯');
select ts_debug('chinese_zh', '卡利姆多');
select ts_debug('chinese_zh', '达纳苏斯');
select ts_debug('chinese_zh', '遗忘海岸');
select ts_debug('chinese_zh', '艾萨拉');
```

```txt
 (n,noun,艾泽,{simple},simple,{艾泽})
 (n,noun,拉斯,{simple},simple,{拉斯})

 (n,noun,泰达,{simple},simple,{泰达})
 (n,noun,希尔,{simple},simple,{希尔})

 (v,verb,遗忘,{simple},simple,{遗忘})
 (s,space,海岸,{},,)

 (n,noun,艾萨,{simple},simple,{艾萨})
 (v,verb,拉,{simple},simple,{拉})
```

Create the customer dict in `/usr/share/postgresql/9.6/tsearch_data/mydict.utf8.txt`:(you can user other name you like, but must in that very dir)

```txt
#word TF  IDF ATTR
艾泽拉斯  1 1 n
卡利姆多  1 1 n
泰达希尔  1 1 n
达纳苏斯  1 1 n
多兰纳尔  1 1 n
艾萨拉  1 1 n
遗忘海岸  1 1 n
```

_Note_: What if dict encoding different from database?
**Note**: According to zhparser document, the TF, IDF, ATTR can be ommited in dict file.
If you do omitted, rember to `ALTER TEXT SEARCH CONFIGURATION chinese_zh ADD MAPPING FOR x WITH simple;`,
or the new wods woun't be used in to_tsvector, hence you can't search for them in query.

Then modify `/var/lib/postgresql/data/posrgresql.conf`, append following line at the end :
`zhparser.extra_dicts = 'mydict.utf8.txt'`

If you use my docker image azurewind.psqlcnft, There is no vi or nano etc in default docker container, you can modify the file with:
`echo "zhparser.extra_dicts = 'mydict.utf8.txt'" >> /var/lib/postgresql/data/postgresql.conf`.

Now restart postgres, and test again:

```sql
select ts_debug('chinese_zh', '艾泽拉斯');
select ts_debug('chinese_zh', '卡利姆多');
select ts_debug('chinese_zh', '达纳苏斯');
select ts_debug('chinese_zh', '遗忘海岸');
select ts_debug('chinese_zh', '艾萨拉');
```

```sql
(n,noun,艾泽拉斯,{simple},simple,{艾泽拉斯})
(n,noun,卡利姆多,{simple},simple,{卡利姆多})
(n,noun,达纳苏斯,{simple},simple,{达纳苏斯})
(n,noun,遗忘海岸,{simple},simple,{遗忘海岸})
(n,noun,艾萨拉,{simple},simple,{艾萨拉})
```

3. Add customer dicts(xdb)

---

According to the zhparser document, xdb format dict is preferred to txt format.
Here is the steps(run in bash):

```sh
# suppose you have already created mydict.utf8.txt in this directory:
cd /usr/share/postgresql/9.6/tsearch_data
# In my docker container, without running this causes lib not found error
ldconfig
# Generate xdb dict from txt as scws document
scws-gen-dict -c UTF8 mydict.utf8.txt mydict.utf8.xdb
# In my testing, root owned xdb dict not accessable to postgresql
chown postgres:postgres mydict.utf8.xdb
# update configure
sed -i 's/mydict\.utf8\.txt/mydict.utf8.xdb/' /var/lib/postgresql/data/postgresql.conf
# verfy configure
tail /var/lib/postgresql/data/postgresql.conf
```

Restart Postgres and test as above.

4. additional resources

---

Found a scel2mmseg tool:
[scel2mmseg orginal](<https://github.com/aboutstudy/scel2mmseg>"sougou dict convert to text")
