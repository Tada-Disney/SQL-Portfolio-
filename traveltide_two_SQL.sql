/*
Question #1:
return users who have booked and completed at least 10 flights, ordered by user_id.

Expected column names: `user_id`
*/

-- q1 solution:
with number_completed_booked_flight as(
Select users.user_id,
count(users.user_id) as n_flights
from users
join sessions on users.user_id = sessions.user_id
where  sessions.cancellation = 'False'
and sessions.flight_booked = 'True'
group by 1
having count(users.user_id) >=10
order by users.user_id
)
select user_id
from number_completed_booked_flight


/*

Question #2: 
Write a solution to report the trip_id of sessions where:

1. session resulted in a booked flight
2. booking occurred in May, 2022
3. booking has the maximum flight discount on that respective day.

If in one day there are multiple such transactions, return all of them.

Expected column names: `trip_id`

*/

-- q2 solution:

WITH discounted_bookings AS (
    SELECT
        sessions.trip_id,
        CAST(sessions.session_start AS DATE) AS booking_date,
        sessions.flight_discount_amount AS discount_amount
    FROM sessions
    WHERE
        sessions.flight_booked = 'true'
        AND EXTRACT(MONTH FROM sessions.session_start) = 5
        AND EXTRACT(YEAR FROM sessions.session_start) = 2022
        AND sessions.flight_discount = 'true'
        AND sessions.cancellation = 'false'
),
max_discount_rank AS (
    SELECT *,
        DENSE_RANK() OVER (PARTITION BY booking_date ORDER BY discount_amount DESC) AS discount_rank
    FROM discounted_bookings
)
SELECT trip_id
FROM max_discount_rank
WHERE discount_rank = 1;


/*
Question #3: 
Write a solution that will, for each user_id of users with greater than 10 flights, 
find out the largest window of days between 
the departure time of a flight and the departure time 
of the next departing flight taken by the user.

Expected column names: `user_id`, `biggest_window`

*/

-- q3 solution:


WITH User_Booking_Dates AS (
    SELECT
        users.user_id,
        CAST(flights.departure_time AS DATE) AS d_time
    FROM
        users
    JOIN
        sessions ON users.user_id = sessions.user_id
    JOIN
        flights ON sessions.trip_id = flights.trip_id
),
User_Booking_Counts AS (
    SELECT
        user_id,
        COUNT(*) AS co
    FROM
        User_Booking_Dates
    GROUP BY 1
    HAVING COUNT(*) > 10
),
User_Booking_Windows AS (
    SELECT
        User_Booking_Dates.user_id,
        User_Booking_Dates.d_time
    FROM
        User_Booking_Dates
    JOIN
        User_Booking_Counts ON User_Booking_Dates.user_id = User_Booking_Counts.user_id
),
User_Max_Window AS (
    SELECT
        *,
        lead(d_time) OVER (PARTITION BY user_id ORDER BY d_time) AS rn
    FROM
        User_Booking_Windows
),
User_booking_ranking as(
select user_id,
(rn - d_time) as biggest_window
from User_Max_Window
), 
ranking_biggest_window as(
select *, 
row_number() over(partition by user_id order by biggest_window desc) as rn 
from User_booking_ranking
where biggest_window is not null 
)
select user_id, biggest_window
from ranking_biggest_window
where rn = 1

/*
Question #4: 
Find the user_id’s of people whose origin airport is Boston (BOS) 
and whose first and last flight were to the same destination. 
Only include people who have flown out of Boston at least twice.

Expected column names: user_id
*/

-- q4 solution:

--Question #4: 
--Find the user_id’s of people whose origin airport is Boston (BOS) and whose
--first and last flight were to the same destination.
--Only include people who have flown out of Boston at least twice.
with leaving_bos as (
SELECT s.user_id,f.departure_time, f.destination_airport 
FROM flights f
join
	sessions s
on
	f.trip_id = s.trip_id
where f.origin_airport = 'BOS'
and s.cancellation = FALSE
),
ranks as (
select *,
DENSE_RANK() OVER(PARTITION BY user_id ORDER BY departure_time ASC) AS RN,
DENSE_RANK() OVER(PARTITION BY user_id ORDER BY departure_time DESC) AS RK
from leaving_bos
order by departure_time
)
select user_id
from
	ranks
where rn = 1 or rk = 1
group by user_id
having count(distinct destination_airport) = 1 and count(user_id) > 1
