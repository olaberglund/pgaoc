begin;
\i ./days/setup.sql

create table day2 (game_plan text);

\copy day2 (game_plan) from './days/data/day2.txt';

select sum(case game_plan
  when 'A X' then 4
  when 'B X' then 1
  when 'C X' then 7
  when 'A Y' then 8
  when 'B Y' then 5
  when 'C Y' then 2
  when 'A Z' then 3
  when 'B Z' then 9
  when 'C Z' then 6
  end)
from day2;

select sum(case game_plan
  when 'A X' then 3
  when 'B X' then 1
  when 'C X' then 2
  when 'A Y' then 4
  when 'B Y' then 5
  when 'C Y' then 6
  when 'A Z' then 8
  when 'B Z' then 9
  when 'C Z' then 7
  end)
from day2;

rollback;
