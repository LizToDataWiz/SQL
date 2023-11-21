-- 1.a Which cross-section of age and gender travels the most?

WITH user_summary AS (
SELECT
  user_id,
  birthdate,
  DATE_PART('YEAR', AGE(CURRENT_DATE, birthdate)) as age,
  gender
FROM users
)
SELECT
	CASE WHEN us.age BETWEEN '16' AND '17' THEN 'Teenagers'
		 WHEN us.age BETWEEN '18' AND '64' THEN 'Adults'
		 ELSE 'Old'
	END AS age_group,
	CASE WHEN us.gender = 'M' THEN 'Male'
  		 WHEN us.gender = 'F' THEN 'Female'
         ELSE 'Other'
	END AS gender,
	COUNT(f.trip_id) AS num_of_trips
FROM user_summary us
INNER JOIN sessions s on us.user_id = s.user_id
INNER JOIN flights f on s.trip_id = f.trip_id
GROUP BY 1,2
ORDER BY num_of_trips DESC

-- Answer: Male adults travels the most with a total of 995,188 trips.

------------------------------------------------------------------------------------------------
-- 1.b How does the travel behavior of customers married with children 
-- compare to childless single customers?

SELECT
	CASE WHEN u.married='True' AND u.has_children='True' THEN 'Married with children'
		WHEN u.married='True' and u.has_children='False' THEN 'Married without children'
		WHEN u.married='False' AND u.has_children='True' THEN 'Single with children'
		WHEN u.married='False' AND u.has_children='False' THEN 'Single without children'
	END AS demographic,
	COUNT(f.trip_id) AS num_of_trips
FROM users u
INNER JOIN sessions s ON u.user_id = s.user_id
INNER JOIN flights f ON s.trip_id = f.trip_id
GROUP BY 1
ORDER BY num_of_trips DESC

/* 1.b

Answer: I have observed that customers who are single without children travels the most,
				while married customers with children are the least to travel.

*/

------------------------------------------------------------------------------------------------
-- 2.a How much session abandonment do we see? 
-- Session abandonment means they browsed but did not book anything.

SELECT
	COUNT(session_id) AS session_abandonment
FROM sessions
WHERE flight_booked = 'False' AND
		  hotel_booked = 'False'
      
-- Answer: 3,072,218 sesssions abandoned.

------------------------------------------------------------------------------------------------
-- 2.b Which demographics abandon sessions disproportionately more than average?

WITH user_summary AS (
	SELECT
		CASE WHEN u.married='True' AND u.has_children='True' THEN 'Married with children'
			 WHEN u.married='True' AND u.has_children='False' THEN 'Married without children'
			 WHEN u.married='False' AND u.has_children='True' THEN 'Single with children'
			 WHEN u.married='False' AND u.has_children='False' THEN 'Single without children'
		END AS demographic,
        user_id,
		COUNT(user_id) AS user_count
    FROM users u
    GROUP BY 1, 2
),
abandoned_sessions AS (
    SELECT
        us.demographic,
        COUNT(DISTINCT s.session_id) as abandoned_sessions
    FROM sessions s
    LEFT JOIN user_summary us ON us.user_id = s.user_id
    WHERE s.flight_booked = 'False' AND s.hotel_booked = 'False'
    GROUP BY 1
),
total_sessions AS (
    SELECT
        us.demographic,
        us.user_count,
        COUNT(DISTINCT s.session_id) AS total_sessions
    FROM user_summary us
    LEFT JOIN sessions s ON us.user_id = s.user_id
    GROUP BY 1, 2
)
SELECT
    ab.demographic,
    COUNT(us.user_id) AS total_users,
    ab.abandoned_sessions::FLOAT / ts.total_sessions AS abandonment_rate
FROM abandoned_sessions ab
LEFT JOIN user_summary us ON ab.demographic = us.demographic
LEFT JOIN total_sessions ts ON ab.demographic = ts.demographic
GROUP BY 1,3
ORDER BY abandonment_rate DESC


-- Answer: Customers who are single with children are most likely to abandon sessions.

------------------------------------------------------------------------------------------------
-- 3.a Explore how customer origin (e.g. home city) influences travel preferences.
WITH user_summary AS (
SELECT
  user_id,
  CONCAT(home_city,', ',home_country) AS customer_origin
FROM users
),
bookings AS (
SELECT
	s.user_id,
	f.trip_id,
	CASE WHEN s.flight_booked='True' THEN 1 ELSE 0 
	END AS flight_booked,
	CASE WHEN s.hotel_booked='True' THEN 1 else 0 
	END AS hotel_booked
FROM sessions s
LEFT JOIN flights f ON s.trip_id = f.trip_id
LEFT JOIN hotels h ON s.trip_id = h.trip_id
)
SELECT
	us.customer_origin,
	SUM(b.flight_booked) AS total_flight_booked,
	SUM(b.hotel_booked) AS total_hotel_booked
FROM bookings b
LEFT JOIN user_summary us ON b.user_id = us.user_id
GROUP BY 1
ORDER BY total_flight_booked DESC
LIMIT 3

-- Answer: The top 3 customers who book flights and hotels live in New York, Los Angeles, and Toronto.

------------------------------------------------------------------------------------------------
-- 4.a Can you make any strategic recommendations based on your answers to the questions above?

/* 4.a

My recommendation is to:
	1. Focus marketing efforts on male adults and single customers without children. 
	2. When designing travel packages and promotions, factors such as 
     the geographical preferences of customers should be considered, with New York, Los Angeles, and Toronto being the key locations to target. 
	3. Enhancing customer experience, website or app optimization is necessary 
     to minimize session abandonment rates, especially for single customers with children.

*/









