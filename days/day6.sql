begin;
\i ./days/setup.sql

create table input (
  id int generated always as identity,
  line text
);

\copy input(line) from './days/data/day6.txt';

with sliding_windows as (
  select ordinality i, array_agg(c) over (
      rows 13 preceding -- 3 for part 1, 13 for part 2
    ) w
  from input
  cross join string_to_table(line, null) with ordinality stt(c)
)
select i
from sliding_windows
cross join unnest(w) t(c)
group by i
having cardinality(array_agg(distinct c)) = 14 -- 4 for part 1, 14 for part 2
limit 1;

rollback;
