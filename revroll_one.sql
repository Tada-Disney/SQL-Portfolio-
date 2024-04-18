/*
Question #1: 
Installers receive performance based year end bonuses. Bonuses are calculated by taking 10% of the total value of parts installed by the installer.

Calculate the bonus earned by each installer rounded to a whole number. Sort the result by bonus in increasing order.

Expected column names: name, bonus
*/

-- q1 solution:

with order_value AS(
SELECT   installers.name, 
  (parts.price * orders.quantity) as total_price
FROM installers
JOIN installs ON installers.installer_id = installs.installer_id
JOIN orders ON installs.order_id = orders.order_id
JOIN parts ON orders.part_id = parts.part_id
)
SELECT order_value.name, round(SUM(order_value.total_price *0.1),0) AS bonus 
FROM order_value
GROUP BY order_value.name
ORDER BY bonus ASC;



/*
Question #2: 
RevRoll encourages healthy competition. The company holds a “Install Derby” where installers face off to see who can change a part the fastest in a tournament style contest.

Derby points are awarded as follows:

- An installer receives three points if they win a match (i.e., Took less time to install the part).
- An installer receives one point if they draw a match (i.e., Took the same amount of time as their opponent).
- An installer receives no points if they lose a match (i.e., Took more time to install the part).

We need to calculate the scores of all installers after all matches. Return the result table ordered by `num_points` in decreasing order. 
In case of a tie, order the records by `installer_id` in increasing order.

Expected column names: `installer_id`, `name`, `num_points`

*/

-- q2 solution:

WITH installers_score AS(
SELECT 
install_derby.installer_one_id AS installer_id,
CASE
  WHEN install_derby.installer_one_time >  install_derby.installer_two_time THEN 0
  WHEN install_derby.installer_one_time <  install_derby.installer_two_time THEN 3
  WHEN install_derby.installer_one_time = install_derby.installer_two_time THEN 1
    END AS score
    FROM  install_derby
UNION ALL 
SELECT install_derby.installer_two_id AS installer_id,
CASE
  WHEN install_derby.installer_two_time < install_derby.installer_one_time THEN 3
  WHEN install_derby.installer_two_time > install_derby.installer_one_time THEN 0
  WHEN install_derby.installer_two_time = install_derby.installer_one_time THEN 1
    END AS score
from install_derby
  )
 SELECT installers.installer_id, installers.name, 
  COALESCE(SUM(score),0) AS num_points 
FROM installers_score
  FULL JOIN installers ON installers_score.installer_id = installers.installer_id
  GROUP BY  installers.installer_id, installers.name
  ORDER BY num_points DESC, installers.name DESC;

/*
Question #3:

Write a query to find the fastest install time with its corresponding `derby_id` for each installer. 
In case of a tie, you should find the install with the smallest `derby_id`.

Return the result table ordered by `installer_id` in ascending order.

Expected column names: `derby_id`, `installer_id`, `install_time`
*/

-- q3 solution:

with all_times as 
(
  select
          derby_id,
          installer_one_id as installer_id,
          installer_one_time as install_time
  from
          install_derby
  union all
  select
          derby_id,
          installer_two_id as installer_id,
          installer_two_time as install_time
  from
          install_derby
  ),
fast_times as
(
  select 
          derby_id, 
          installer_id,
          install_time,
          rank() over (partition by installer_id order by install_time,derby_id) as _rank
  from
          all_times
 )
 select derby_id,installer_id,install_time
 from fast_times
 where _rank = 1;

/*
Question #4: 
Write a solution to calculate the total parts spending by customers paying for installs on each Friday of every week in November 2023. 
If there are no purchases on the Friday of a particular week, the parts total should be set to `0`.

Return the result table ordered by week of month in ascending order.

Expected column names: `november_fridays`, `parts_total`
*/

-- q4 solution:

WITH november_friday_value AS(
  SELECT
    customers.customer_id,
    (parts.price * orders.quantity) AS total_price,
    installs.install_date AS November_date
FROM
    customers
FULL OUTER JOIN
    orders ON customers.customer_id = orders.customer_id
 FULL OUTER JOIN
    installs ON orders.order_id = installs.order_id
FULL OUTER JOIN
    parts ON orders.part_id = parts.part_id
WHERE
    
     EXTRACT(MONTH FROM installs.install_date) = 11
    AND EXTRACT(DOW FROM installs.install_date) = 5 -- 5 represents Friday & DOW(day of week)
)
SELECT november_friday_value.November_date, COALESCE(SUM(november_friday_value.total_price),0) as parts_total
FROM november_friday_value
GROUP BY november_friday_value.November_date
ORDER BY november_friday_value.November_date;

