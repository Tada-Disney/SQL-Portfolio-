/*
Question #1:

Identify installers who have participated in at least one installer competition by name.

Expected column names: name
*/

-- q1 solution:

with installer_participants as (
    select 
        install_derby.installer_one_id as id, 
        installers.name
    from install_derby
    join installers on install_derby.installer_one_id = installers.installer_id

    union all 

    select 
        install_derby.installer_two_id as id, 
        installers.name
    from install_derby
    join installers on install_derby.installer_two_id = installers.installer_id
)
select distinct name 
from installer_participants;



/*
Question #2: 
Write a solution to find the third transaction of every customer, where the spending on the preceding two transactions is lower than the spending on the third transaction. 
Only consider transactions that include an installation, and return the result table by customer_id in ascending order.

Expected column names: customer_id, third_transaction_spend, third_transaction_date
*/

-- q2 solution:

with transaction_details as (
    select 
        customers.customer_id,
        installs.install_date,
        (parts.price * orders.quantity) as order_value
    from installs
    join orders on installs.order_id = orders.order_id
    join parts on orders.part_id = parts.part_id
    join customers on orders.customer_id = customers.customer_id
    order by installs.install_date
),
third_transaction_details as (
    select 
        customer_id,
        order_value,
        install_date as third_transaction_date,
        row_number() over(partition by customer_id order by install_date asc, order_value desc) as third_transaction
    from transaction_details
)
select 
    third_transaction_details.customer_id,
    third_transaction_details.order_value,
    third_transaction_details.third_transaction_date
from third_transaction_details
join third_transaction_details ktt on third_transaction_details.customer_id = ktt.customer_id
join third_transaction_details ps on third_transaction_details.customer_id = ps.customer_id
where third_transaction_details.third_transaction = 3
and third_transaction_details.order_value > ktt.order_value
and ktt.third_transaction = 1
and third_transaction_details.order_value > ps.order_value
and ps.third_transaction = 2;


/*
Question #3: 
Write a solution to report the **most expensive** part in each order. 
Only include installed orders. In case of a tie, report all parts with the maximum price. 
Order by order_id and limit the output to 5 rows.

Expected column names: `order_id`, `part_id`

*/

with installed_parts as (
    select 
        parts.part_id,
        orders.order_id,
        row_number() over(partition by parts.part_id order by parts.price desc) as rn
    from orders
    join parts on orders.part_id = parts.part_id
    join installs on orders.order_id = installs.order_id
    order by orders.order_id
)
select 
    order_id,
    part_id
from installed_parts
limit 5;




/*
Question #4: 
Write a query to find the installers who have completed installations for at least four consecutive days. 
Include the `installer_id`, start date of the consecutive installations period and the end date of the consecutive installations period. 

Return the result table ordered by `installer_id` in ascending order.

E**xpected column names: `installer_id`, `consecutive_start`, `consecutive_end`**
*/

-- q4 solution:

WITH consecutive_periods AS (
    SELECT
        installer_id,
        CAST(installs.install_date AS DATE) AS consecutive_start
    FROM installs
),
consecutive_periods_with_end AS (
    SELECT
        installer_id,
        CASE
            WHEN consecutive_start = LEAD(consecutive_start) OVER (PARTITION BY installer_id ORDER BY consecutive_start)
            THEN NULL
            ELSE consecutive_start
        END 
    FROM consecutive_periods
),
three_day_consecutive_periods AS (
    SELECT
        installer_id,
        consecutive_start,
        LEAD(consecutive_start, 3) OVER(PARTITION BY installer_id ORDER BY consecutive_start) AS consecutive_end
    FROM consecutive_periods_with_end
    WHERE consecutive_start IS NOT NULL
)
SELECT *
FROM three_day_consecutive_periods
WHERE consecutive_end - consecutive_start = 3;


