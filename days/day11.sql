begin;

\i ./days/setup.sql

create table input (
  line_number int generated always as identity primary key,
  line text
);

\copy input(line) from './days/data/day11.txt';
\timing

with recursive monkey_desc as (
  select monkey_id::text, array_agg(line) line from (
    select sum((line like 'Monkey%')::int) over (order by line_number) - 1 monkey_id, line
    from input
  )
  group by monkey_id
),
monkey_items as (
  select
    monkey_id,
    line,
    array_agg(item[1]::int) as items
  from monkey_desc
  cross join regexp_matches(line[2], '\d+', 'g') i(item)
  group by monkey_id, line
),
keep_away_start as (
  select (array_agg(monkey_id order by monkey_id desc))[1] last_monkey_id, jsonb_object_agg(monkey_id, json_build_object(
            'inspected', 0,
            'items',  items,
            'op',       (regexp_match(line[3], '(\*|\+)'))[1],
            'op_val',      (regexp_match(line[3], '\d+'))[1]::int,
            'test',     (regexp_match(line[4], '\d+'))[1]::int,
            'if_true',     (regexp_match(line[5], '\d+'))[1]::int,
            'if_false',    (regexp_match(line[6], '\d+'))[1]::int
          )) as monkeys
  from monkey_items
),
base as (
  select exp(sum(ln((value->>'test')::numeric)))::int lcm
  from keep_away_start, jsonb_each(monkeys)
),
keep_away as (
    select last_monkey_id, 0 round, '0' monkey_id, monkeys, lcm from keep_away_start, base
    union
    select last_monkey_id, round + case when monkey_id = last_monkey_id then 1 else 0 end,
        ((monkey_id::int + 1) % (last_monkey_id::int + 1))::text,
        monkeys ||
            jsonb_build_object(
                monkey_id, monkeys->monkey_id || jsonb_build_object(
                    'items', '[]'::jsonb,
                    'inspected', (monkeys->monkey_id->>'inspected')::int +
                        jsonb_array_length(monkeys->monkey_id->'items')
                )
            ) ||
            coalesce((
                select jsonb_object_agg(
                    target_monkey,
                    monkeys->target_monkey || jsonb_build_object(
                      'items', monkeys->target_monkey->'items' || to_jsonb(items)
                    )) new_monkeys
                from (
                  select
                      case new_item_worry % (monkeys->monkey_id->>'test')::bigint
                        when 0 then monkeys->monkey_id->>'if_true'
                        else monkeys->monkey_id->>'if_false'
                      end target_monkey,
                      array_agg(new_item_worry) items
                  from jsonb_array_elements_text(monkeys->monkey_id->'items') t(item_worry)
                  cross join lateral (
                      select
                          case monkeys->monkey_id->>'op'
                            when '*' then item_worry::bigint * coalesce((monkeys->monkey_id->>'op_val')::int, item_worry::bigint)
                            else item_worry::bigint + coalesce((monkeys->monkey_id->>'op_val')::int, item_worry::bigint)
                          end % lcm as new_item_worry -- divide 3 for part 1
                  )
                  group by 1
                )
          ), '{}'::jsonb),
    lcm
    from keep_away
  where round < 10000 -- 20 for part 1
),
most_active as (
  select (value->'inspected')::int inspected
  from keep_away, jsonb_each(monkeys)
  where round = (select max(round) from keep_away)
  order by (value->>'inspected')::int desc
  limit 2
)
select exp(sum(ln(inspected)))::bigint from most_active;


rollback;
