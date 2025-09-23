begin;

\i ./days/setup.sql

create table input (
  line_number int generated always as identity primary key,
  line text
);

\copy input(line) from './days/data/day10.txt';

-- with expanded_instruction as (
--     select row_number() over () clock,
--         case when row_number() over (partition by line_number) / count(*) over (partition by line_number)::float <> 1 then 'noop' else line end
--     from input
--     cross join generate_series(1,
--       case
--         when line like 'addx%' then 2
--         else 1
--       end
--     )
-- )
-- select sum((clock+1) * amount) from (
--   select
--     clock, sum(coalesce((regexp_match(line, 'addx (-?\d+)'))[1]::int, 0)) over (order by clock) + 1 amount
--   from expanded_instruction
-- )
-- where clock % 40 = 19 and clock <> 0;

-- Lesson learnt again: just solve the problem, don't complicate it,
-- so I like this solution more, proposed elsewhere:
-- with cycles as (
--     select row_number() over (order by d.line_number, s.ord) cycle,
--         case when s.ord = 2 then s.v::int end v
--     from input as d
--     cross join lateral string_to_table(d.line, ' ') with ordinality as s (v, ord)
-- ),
-- calc as (
--     select cycle, sum(v) over (order by cycle rows unbounded preceding exclude current row) + 1 x
--     from cycles
-- )
-- select sum(cycle * x)
-- from calc
-- where cycle % 40 = 20;

-- part 2

with cycles as (
    select row_number() over (order by d.line_number, s.ord) cycle,
        case when s.ord = 2 then s.v::int end v
    from input as d
    cross join lateral string_to_table(d.line, ' ') with ordinality as s (v, ord)
),
register_x as (
    select cycle, coalesce(sum(v) over (order by cycle rows unbounded preceding exclude current row), 0) + 1 x
    from cycles
),
drawn_pixel as (
    select (cycle - 1) / 40 line,
        case when ((cycle - 1) % 40) between x-1 and x+1 -- replaced any+array w/ between
            then '#' else '.'
        end pixel
    from register_x
)
select string_agg(pixel, '') from drawn_pixel
group by line order by line;


rollback;
