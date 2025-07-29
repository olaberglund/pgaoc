begin;
\i ./days/setup.sql

create table day3 (
  id int generated always as identity,
  rucksack text
);

\copy day3(rucksack) from './days/data/day3.txt';

create function char_prio(c text) returns int
return case
    when lower(c) = c then ascii(c) - 96
    else ascii(c) - 38
end;

-- with compartments as (
--     select id,
--            substring(rucksack for char_length(rucksack) / 2) comp1,
--            substring(rucksack from char_length(rucksack) / 2 + 1) comp2
--     from day3
-- ), intersection as (
--     select id, c from compartments, string_to_table(comp1, null) c1(c)
--     intersect distinct
--     select id, c from compartments, string_to_table(comp2, null) c2(c)
-- )
-- select sum(char_prio(c)) from intersection;

with grouped_bags as (
    select (id - 1) / 3 group_id, array_agg(rucksack) rucksacks from day3 group by group_id
), intersection as (
    select group_id, rs from grouped_bags, string_to_table(rucksacks[1], null) t(rs)
    intersect distinct
    select group_id, rs from grouped_bags, string_to_table(rucksacks[2], null) t(rs)
    intersect distinct
    select group_id, rs from grouped_bags, string_to_table(rucksacks[3], null) t(rs)
)
select sum(char_prio(rs)) from intersection;

rollback;
