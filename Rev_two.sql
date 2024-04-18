/*
Question #1:

Write a query to find the customer(s) with the most orders. 
Return only the preferred name.

Expected column names: preferred_name
*/

-- q1 solution:

WITH CustomerOrderCounts AS (
  SELECT
    c.customer_id,
    c.preferred_name,
    COUNT(o.order_id) AS total_orders
  FROM customers c
  JOIN orders o ON c.customer_id = o.customer_id
  GROUP BY c.preferred_name, c.customer_id
  ORDER BY total_orders DESC
),
RankedCustomerOrders AS (
  SELECT *,
    ROW_NUMBER() OVER (ORDER BY total_orders DESC) AS rn
  FROM CustomerOrderCounts
)

SELECT preferred_name
from RankedCustomerOrders
where rn = 1


/*
Question #2: 
RevRoll does not install every part that is purchased. 
Some customers prefer to install parts themselves. 
This is a valuable line of business 
RevRoll wants to encourage by finding valuable self-install customers and sending them offers.

Return the customer_id and preferred name of customers 
who have made at least $2000 of purchases in parts that RevRoll did not install. 

Expected column names: customer_id, preferred_name

*/

-- q2 solution:

with order_value as(
select c.customer_id, c.preferred_name, (p.price * o.quantity) as n_price
from customers c
join orders o on c.customer_id = o.customer_id
join parts p on o.part_id = p.part_id
left join installs i on o.order_id = i.order_id
left join installers ins on i.installer_id = ins.installer_id
where ins.installer_id is null
  ),
  total_purchase as(
  select customer_id,preferred_name, sum(n_price) as total_price
  from order_value 
  group by preferred_name, customer_id
  )
  select customer_id, preferred_name
  from total_purchase
  where total_price >= 2000
  

/*
Question #3: 
Report the id and preferred name of customers who bought an Oil Filter and Engine Oil 
but did not buy an Air Filter since we want to recommend these customers buy an Air Filter.
Return the result table ordered by `customer_id`.

Expected column names: customer_id, preferred_name

*/

-- q3 solution:

WITH Engine_Oil_Orders AS (
  SELECT
    c.customer_id,
    c.preferred_name,
    p.name
  FROM customers c
  JOIN orders o ON c.customer_id = o.customer_id
  JOIN parts p ON o.part_id = p.part_id
  WHERE p.name = 'Engine Oil'
),
Oil_Filter_Orders AS (
  SELECT
    c.customer_id,
    c.preferred_name,
    p.name
  FROM customers c
  JOIN orders o ON c.customer_id = o.customer_id
  JOIN parts p ON o.part_id = p.part_id
  WHERE p.name = 'Oil Filter'
),
Air_Filter_Orders AS (
  SELECT
    c.customer_id,
    c.preferred_name
  FROM customers c
  JOIN orders o ON c.customer_id = o.customer_id
  JOIN parts p ON o.part_id = p.part_id
  WHERE p.name = 'Air Filter'
)
SELECT DISTINCT
  Engine_Oil_Orders.customer_id,
  Engine_Oil_Orders.preferred_name
FROM Engine_Oil_Orders
JOIN Oil_Filter_Orders ON Engine_Oil_Orders.customer_id = Oil_Filter_Orders.customer_id
LEFT JOIN Air_Filter_Orders ON Engine_Oil_Orders.customer_id = Air_Filter_Orders.customer_id
WHERE Oil_Filter_Orders.customer_id NOT IN (SELECT customer_id FROM Air_Filter_Orders)
ORDER BY Engine_Oil_Orders.customer_id;

/*
Question #4: 

Write a solution to calculate the cumulative part summary for every part that 
the RevRoll team has installed.

The cumulative part summary for an part can be calculated as follows:

- For each month that the part was installed, 
sum up the price*quantity in **that month** and the **previous two months**. 
This is the **3-month sum** for that month. 
If a part was not installed in previous months, 
the effective price*quantity for those months is 0.
- Do **not** include the 3-month sum for the **most recent month** that the part was installed.
- Do **not** include the 3-month sum for any month the part was not installed.

Return the result table ordered by `part_id` in ascending order. In case of a tie, order it by `month` in descending order. Limit the output to the first 10 rows.

Expected column names: part_id, month, part_summary
*/

-- q4 solution:

WITH calendar AS (
  SELECT EXTRACT(MONTH FROM generate_series('2023-01-01'::date, '2023-12-31'::date, '1 month')) AS month
),
orders AS (
  SELECT
    parts.part_id,
    orders.quantity,
    parts.price,
    EXTRACT(MONTH FROM installs.install_date) AS month
  FROM parts
  LEFT JOIN orders ON parts.part_id = orders.part_id
  LEFT JOIN installs ON orders.order_id = installs.order_id
),
order_value AS (
  SELECT
    part_id,
    month,
    CASE
      WHEN month IS NOT NULL THEN (quantity * price)
      ELSE 0
    END AS order_value
  FROM orders
),
total_order_value AS (
  SELECT
    part_id,
    month,
    SUM(order_value) AS total_sum
  FROM order_value
  GROUP BY part_id, month
  ),
part_summary AS (
  SELECT
    c.month,
    p.part_id,
    COALESCE(total_sum, 0) +
      LAG(COALESCE(total_sum, 0), 1, 0) OVER (PARTITION BY p.part_id ORDER BY c.month) +
      LAG(COALESCE(total_sum, 0), 2, 0) OVER (PARTITION BY p.part_id ORDER BY c.month) AS part_summary
  FROM calendar c
  CROSS JOIN (SELECT DISTINCT part_id FROM order_value) p
  LEFT JOIN total_order_value ON c.month = total_order_value.month AND p.part_id = total_order_value.part_id
  WHERE c.month != 12 -- Exclude the most current month
)
SELECT
  part_id,
  month,
  part_summary
FROM part_summary
ORDER BY part_id ASC, month DESC
LIMIT 10;


