begin;
\i ./days/setup.sql
\timing

create table input (
  line_number int generated always as identity primary key,
  line text
);

\copy input(line) from './days/data/day8.txt';

with tree_map as (
  select x, line_number as y, height::int
  from input
  cross join string_to_table(line, null) with ordinality as t(height, x)
),
tree_sight as (
  select x, y,
      height > coalesce(max(height) over from_west,  -1) or
      height > coalesce(max(height) over from_east,  -1) or
      height > coalesce(max(height) over from_north, -1) or
      height > coalesce(max(height) over from_south, -1) visible
  from tree_map
  window from_west  as (partition by y order by x asc  rows unbounded preceding exclude current row),
         from_east  as (partition by y order by x desc rows unbounded preceding exclude current row),
         from_north as (partition by x order by y asc  rows unbounded preceding exclude current row),
         from_south as (partition by x order by y desc rows unbounded preceding exclude current row)
)
select count(*) from tree_sight where visible;

with tree_map as (
  select x, line_number as y, height::int
  from input
  cross join string_to_table(line, null) with ordinality as t(height, x)
),
house_sight as (
  select x, y, height,
      reversed(array_agg(height) over northward) as northward,
      reversed(array_agg(height) over westward) as westward,
      reversed(array_agg(height) over southward) as southward,
      reversed(array_agg(height) over eastward) as eastward
  from tree_map
  window northward as (partition by x order by y asc  rows between unbounded preceding and current row exclude current row),
         westward  as (partition by y order by x asc  rows between unbounded preceding and current row exclude current row),
         southward as (partition by x order by y desc rows between unbounded preceding and current row exclude current row),
         eastward  as (partition by y order by x desc rows between unbounded preceding and current row exclude current row)
)
select x, y, coalesce(e * w * n * s, 0) score
from tree_map
join house_sight using (x, y, height)
cross join lateral (
    select
        coalesce(array_position(array_agg(height > h_n), false), cardinality(array_agg(h_n) filter (where h_n is not null))) n,
        coalesce(array_position(array_agg(height > h_w), false), cardinality(array_agg(h_w) filter (where h_w is not null))) w,
        coalesce(array_position(array_agg(height > h_s), false), cardinality(array_agg(h_s) filter (where h_s is not null))) s,
        coalesce(array_position(array_agg(height > h_e), false), cardinality(array_agg(h_e) filter (where h_e is not null))) e
    from unnest(northward, westward, southward, eastward) t(h_n, h_w, h_s, h_e)
  ) t
order by score desc
limit 1;

rollback;
