begin;
\i ./days/setup.sql

create table input (
  id int generated always as identity,
  line text
);

\copy input(line) from './days/data/day5.txt';

create table instruction as
select id - 10 as id, m[1]::int amount, m[2] src, m[3] dst
from input, regexp_matches(line, 'move (\d+) from (\d) to (\d)') m;

create unlogged table stacks as
with crates as (
  select id,
         generate_series(1, length(line)) as pos,
         substr(line, generate_series(1, length(line)), 1) as ch
  from input
  where line like '%[%'
),
letters as (
  select id, ch, ((pos - 2) / 4 + 1) as stack
  from crates
  where ch ~ '[A-Z]'
)
select stack, string_agg(ch, '') as crates
from letters group by stack;

create or replace function apply(state jsonb, ins instruction, is9001 boolean)
returns jsonb
begin atomic
select
    state ||
    jsonb_build_object(
      ins.src,
      right(state->>ins.src, length(state->>ins.src) - ins.amount),
      ins.dst,
      case when is9001
        then left(state->>ins.src, ins.amount) || (state->>ins.dst)
        else reverse(left(state->>ins.src, ins.amount)) || (state->>ins.dst)
      end
    );
end;

with recursive timeline(i, state_1, state_2) as (
    select 0, jsonb_object_agg(stack, crates), jsonb_object_agg(stack, crates)
    from stacks
    union all
    select i + 1, apply(state_1, ins, false), apply(state_2, ins, true)
    from timeline
    join instruction ins on id = i + 1
),
final as (
    select *
    from timeline
    order by i desc
    limit 1
)
select
    (select string_agg(left(value,1), '') from jsonb_each_text(state_1)) as part_1,
    (select string_agg(left(value,1), '') from jsonb_each_text(state_2)) as part_2
from final;

rollback;
