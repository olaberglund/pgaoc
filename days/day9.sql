begin;

\i ./days/setup.sql

create table input (
  line_number int generated always as identity primary key,
  line text
);

\copy input(line) from './days/data/day9.txt';

create function new_tail(h_x int, h_y int, t_x int, t_y int)
returns vec2
begin atomic
select
  case when far then t_x + sign(h_x - t_x)::int else t_x end,
  case when far then t_y + sign(h_y - t_y)::int else t_y end
from (select dist(h_x, h_y, t_x, t_y) >= 2 far);
end;

-- first star

-- with recursive step as materialized (
--   select x dx, y dy, row_number() over () line_number
--   from input
--   cross join
--     unnest(array_fill(case
--       when line like 'U%' then (0, 1)::vec2
--       when line like 'L%' then (-1,0)::vec2
--       when line like 'D%' then (0,-1)::vec2
--       when line like 'R%' then (1, 0)::vec2
--     end, array[substring(line, 3)::int]))
-- ),
-- walk as (
--   select 0 ln, 0 h_x, 0 h_y, 0 t_x, 0 t_y
--   union all
--   select new_head.ln, new_head.x, new_head.y, new_tail.x, new_tail.y
--   from step
--   join walk on line_number = ln + 1
--   cross join lateral (select ln + 1, h_x + dx, h_y + dy) new_head(ln, x, y)
--   cross join new_tail(new_head.x, new_head.y, t_x, t_y)
-- )
-- select count(*) from (select distinct t_x, t_y from walk);

-- second star:

with recursive step as materialized (
  select x dx, y dy, row_number() over () line_number
  from input
  cross join
    unnest(array_fill(case
      when line like 'U%' then (0, 1)::vec2
      when line like 'L%' then (-1,0)::vec2
      when line like 'D%' then (0,-1)::vec2
      when line like 'R%' then (1, 0)::vec2
    end, array[substring(line, 3)::int]))
),
walk as (
  select 0 ln, 0 h_x, 0 h_y, array[(0,0), (0,0), (0,0), (0,0), (0,0), (0,0), (0,0), (0,0), (0,0)]::vec2[] tails
  union all
  select new_head.ln, new_head.x, new_head.y, array[(n1.x, n1.y), (n2.x,n2.y), (n3.x, n3.y), (n4.x, n4.y), (n5.x, n5.y), (n6.x, n6.y), (n7.x, n7.y), (n8.x, n8.y), (n9.x, n9.y)]::vec2[]
  from step
  join walk on line_number = ln + 1
  cross join lateral (select ln + 1, h_x + dx, h_y + dy) new_head(ln, x, y)
  cross join new_tail(new_head.x, new_head.y, (tails[1]).x, (tails[1]).y) n1
  cross join new_tail(n1.x, n1.y, (tails[2]).x, (tails[2]).y) n2
  cross join new_tail(n2.x, n2.y, (tails[3]).x, (tails[3]).y) n3
  cross join new_tail(n3.x, n3.y, (tails[4]).x, (tails[4]).y) n4
  cross join new_tail(n4.x, n4.y, (tails[5]).x, (tails[5]).y) n5
  cross join new_tail(n5.x, n5.y, (tails[6]).x, (tails[6]).y) n6
  cross join new_tail(n6.x, n6.y, (tails[7]).x, (tails[7]).y) n7
  cross join new_tail(n7.x, n7.y, (tails[8]).x, (tails[8]).y) n8
  cross join new_tail(n8.x, n8.y, (tails[9]).x, (tails[9]).y) n9
)
select count(*)
from (select distinct (tails[9]).x, (tails[9]).y from walk);

rollback;
