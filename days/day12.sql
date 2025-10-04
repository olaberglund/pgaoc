begin;

\i ./days/setup.sql

create table input (
  line_number int generated always as identity primary key,
  line text
);

\copy input(line) from './days/data/day12.txt';

create temp table map as
select i x, line_number y, chr,
  ascii(case
      when chr = 'S' then 'a'
      when chr = 'E' then 'z'
      else chr
  end) height
from input
cross join string_to_table(line, null) with ordinality _(chr, i);

create or replace function shortest_distance(start text, finish text, possible_move_I text) returns int as $$
declare
  root point := (select point(x,y) from map where chr = start);
  Q point[] := array[root];
  D int[] := array[0];
  v point;
  dv int;
  w point;
begin
  create temp table explored(pos point);
  insert into explored (pos) values (root);

  while cardinality(Q) > 0 loop
    v := Q[1]; dv := D[1];
    Q := Q[2:]; D := D[2:];

    if (select chr = finish from map where x = v[0] and y = v[1]) then
      return dv;
    end if;

    for w in
      execute format('select move from %I where curr ~= $1', possible_move_I) using v
    loop
      if not exists (select 1 from explored e where e.pos ~= w) then
        insert into explored (pos) values (w);
        Q := Q || w;
        D := D || dv + 1;
      end if;
    end loop;
  end loop;
  return null;
end;
$$ language plpgsql;

-- part 1

create temp table possible_move_1 as
select m1.chr, point(m1.x, m1.y) as curr, point(m2.x, m2.y) as move
from map m1
join map m2
  on abs(m2.x - m1.x) + abs(m2.y - m1.y) = 1
  and m2.height - m1.height <= 1;

select shortest_distance('S', 'E', 'possible_move_1');
drop table explored;

-- part 2

create temp table possible_move_2 as
select m1.chr, point(m1.x, m1.y) as curr, point(m2.x, m2.y) as move
from map m1
join map m2
  on abs(m2.x - m1.x) + abs(m2.y - m1.y) = 1
  and m1.height - m2.height <= 1;

select shortest_distance('E', 'a', 'possible_move_2');

rollback;
