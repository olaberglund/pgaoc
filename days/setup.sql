\set QUIET 1
set client_min_messages to warning;

create or replace function reversed(anyarray) returns anyarray as $$
select array(
    select $1[i]
    from generate_subscripts($1,1) as s(i)
    order by i desc
);
$$ language 'sql' strict immutable;

create type vec2 as (x int, y int);

create function dist(x1 int, y1 int, x2 int, y2 int)
returns numeric
return sqrt(abs(x1 - x2)^2 + abs(y1 - y2)^2);

