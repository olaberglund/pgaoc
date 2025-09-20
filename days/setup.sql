\set QUIET 1
set client_min_messages to warning;

create or replace function reversed(anyarray) returns anyarray as $$
select array(
    select $1[i]
    from generate_subscripts($1,1) as s(i)
    order by i desc
);
$$ language 'sql' strict immutable;
