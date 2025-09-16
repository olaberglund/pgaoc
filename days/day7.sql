begin;
\i ./days/setup.sql

create table input (
  id int generated always as identity primary key,
  line text
);

\copy input(line) from './days/data/day7.txt';

with recursive
parsed_commands as (
  select sum((line like '$ cd%')::int) over (order by id) as cd_id, line
  from input where line <> '$ ls'
),
cd_groups as (
  select cd_id, (array_agg(line))[1] as cd_cmd, (array_agg(line))[2:] as listed_files
  from parsed_commands
  group by 1
),
directory_paths(cd_id, path) as (
  select 0::bigint, array[]::text[]
  union all
  select
    g.cd_id,
    case
      when g.cd_cmd = '$ cd ..' then trim_array(p.path, 1)
      else p.path || substring(g.cd_cmd from '\$ cd (.*)')
    end
  from directory_paths p
  join cd_groups g on p.cd_id + 1 = g.cd_id
),
all_files as (
  select p.path || size_name[2] as path, size_name[1]::int as size
  from directory_paths p
  join cd_groups g on p.cd_id = g.cd_id
  cross join lateral unnest(g.listed_files) as file
  cross join lateral regexp_split_to_array(file, ' ') as size_name
  where file !~ 'dir'
),
directory_sizes as (
  select parent.path, sum(child.size) as total_size
  from (select distinct path[:i] from all_files, generate_series(1, cardinality(path)-1) t(i)) parent(path)
  join all_files child on parent.path = child.path[1:cardinality(parent.path)]
  group by parent.path
)
-- select sum(total_size)
-- from directory_sizes
-- where total_size <= 100000;
select min(d.total_size)
from directory_sizes d
join directory_sizes root on root.path = array['/']
where d.total_size >= 30_000_000 - (70_000_000 - root.total_size);

rollback;

