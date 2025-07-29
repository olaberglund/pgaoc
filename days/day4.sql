begin;
\i ./days/setup.sql

create table input (
  id int generated always as identity,
  line text
);

\copy input(line) from './days/data/day4.txt';

create function mk_range(text)
returns int4range
return ('[' || regexp_replace($1, '-', ',') || ']')::int4range;

with ranges(r1, r2) as (
    select mk_range(arr[1]), mk_range(arr[2])
    from input, regexp_split_to_array(line, ',') a(arr)
)
--select count(*) from ranges where r1 @> r2 or r1 <@ r2; Part 1
select count(*) from ranges where r1 && r2;

rollback;
