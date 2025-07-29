begin;
\i ./days/setup.sql

create table day1 (
  id int generated always as identity,
  calories int
);

\copy day1 (calories) from './days/data/day1.txt' with null '';

with grouped as (
  select calories, sum((calories is null)::int) over (order by id) group_id from day1
),
-- select group_id, sum(calories) cal_sum from grouped group by group_id order by cal_sum desc; -- Part 1
-- Part 2:
sums as (
  select group_id, sum(calories) cal_sum from grouped group by group_id order by cal_sum desc limit 3
)
select sum(cal_sum) from sums;

rollback;
