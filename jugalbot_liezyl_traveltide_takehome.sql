/*

Project Details:

e-booking startup TravelTide is a hot new player in the online travel industry. 
It has experienced steady growth since it was founded at the tail end of the covid pandemic (2021-04) on the strength 
of its data aggregation and search technology.

The TravelTide team has recently shifted focus from aggressively acquiring new customers to better serving their existing customers. 
In order to achieve better service, the team recognizes that it is important to understand customer demographics and behavior.

The task is to help the TravelTide team develop an understanding of their customers and give recommendations.

TravelTide Database: postgresql://Test:bQNxVzJL4g6u@ep-noisy-flower-846766.us-east-2.aws.neon.tech/TravelTide?sslmode=require

*/

-------------      1.a Which cross-section of age and gender travels the most?         --------------

-- Calculate user age and gender summary
WITH user_summary AS (
    SELECT
        user_id,
        birthdate,
        DATE_PART('YEAR', AGE(CURRENT_DATE, birthdate)) as age,
        gender
    FROM users
)
-- Analyze travel patterns by age group and gender
SELECT
    CASE 
        WHEN us.age BETWEEN 16 AND 17 THEN 'Teenagers'
        WHEN us.age BETWEEN 18 AND 64 THEN 'Adults'
        ELSE 'Old'
    END AS age_group,
    CASE 
        WHEN us.gender = 'M' THEN 'Male'
        WHEN us.gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS gender,
    COUNT(f.trip_id) AS num_of_trips
FROM 
    user_summary us
    INNER JOIN sessions s ON us.user_id = s.user_id
    INNER JOIN flights f ON s.trip_id = f.trip_id
GROUP BY 1, 2
ORDER BY num_of_trips DESC

/* 1.a Analysis Result: 
       The demographic with the highest travel frequency is Male Adults, totaling 995,131 trips.
*/

---------------    1.b How does the travel behavior of customers married with children  ------------------ 
---------------        compare to childless single customers?                           ------------------

-- Analyze travel behavior based on marital and parental status
SELECT
    CASE 
        WHEN u.married = 'True' AND u.has_children = 'True' THEN 'Married with children'
        WHEN u.married = 'True' AND u.has_children = 'False' THEN 'Married without children'
        WHEN u.married = 'False' AND u.has_children = 'True' THEN 'Single with children'
        WHEN u.married = 'False' AND u.has_children = 'False' THEN 'Single without children'
    END AS demographic,
    COUNT(S.trip_id) AS num_of_trips
FROM 
    users u
    INNER JOIN sessions s ON u.user_id = s.user_id
WHERE s.flight_booked = 'True' OR s.hotel_booked = 'True'
GROUP BY 1
ORDER BY num_of_trips DESC

/* 1.b Analysis Result:
   Customers who are single without children tend to travel the most with 1,073,982 trips,
   while married customers with children are observed to be the least frequent travelers 
   with only 353,512 trips. This indicates that the number of trips for single customers without children 
   is approximately 204% more than the number of trips for customers who are married with children.
*/

----------------     2.a How much session abandonment do we see?                         -----------------------------
----------------     Session abandonment means they browsed but did not book anything.   -----------------------------

-- Calculate the number of sessions with abandonment (browsing without booking)
SELECT
    COUNT(session_id) AS session_abandonment
FROM 
    sessions
WHERE 
    flight_booked = 'False' AND hotel_booked = 'False'

/* 2.a Analysis Result:
   A total of 3,072,218 sessions were abandoned, meaning users browsed without making any 
   flight or hotel bookings.
*/

----------------   2.b Which demographics abandon sessions disproportionately more than average? ---------------------

-- Create a user summary, calculate the age based on birtdate, and categorize users into age groups.
WITH user_summary AS (
    SELECT
        user_id,
        COUNT(user_id) AS user_count,
        CASE 
            WHEN age BETWEEN 13 AND 17 THEN 'Teenagers'
            WHEN age BETWEEN 18 AND 64 THEN 'Adults'
            ELSE 'Old'
        END AS age_group
    FROM (
        SELECT
            user_id,
            DATE_PART('YEAR', AGE(CURRENT_DATE, birthdate)) AS age
        FROM users
    ) AS T1
    GROUP BY 1,3
),
-- Calculate abandoned sessions
abandoned_sessions AS (
    SELECT
        us.age_group,
        COUNT(DISTINCT s.session_id) AS abandoned_sessions
    FROM sessions s
    LEFT JOIN user_summary us ON us.user_id = s.user_id
    WHERE s.flight_booked = 'False' AND s.hotel_booked = 'False'
    GROUP BY 1
),
-- calculate total sessions
total_sessions AS (
    SELECT
        age_group,
        user_count,
        COUNT(DISTINCT s.session_id) AS total_sessions
    FROM user_summary
    LEFT JOIN sessions s ON user_summary.user_id = s.user_id
    GROUP BY 1, 2
)
-- Calculate the abandonment rate and average abandonment rate
SELECT
    us.age_group,
    COUNT(user_id) AS total_users,
    CAST(AVG(ab.abandoned_sessions::FLOAT / ts.total_sessions) AS numeric(10,2)) AS abandonment_rate,
    CAST(AVG(ab.abandoned_sessions::FLOAT / ts.total_sessions) OVER() as numeric(10,2)) AS avg_abandonment_rate
FROM user_summary us
LEFT JOIN abandoned_sessions ab ON us.age_group = ab.age_group
LEFT JOIN total_sessions ts ON us.age_group = ts.age_group
GROUP BY us.age_group, abandoned_sessions, total_sessions
ORDER BY abandonment_rate DESC

/* 2.b Analysis Result:
       Teenagers and Old customers are observed to have 74-75% abandonment rate, 
       which is approximately 10% higher than the overall average rate of 68%.
*/

-------------     3.a Explore how customer origin influences travel preferences.     -----------------------

-- Calculate user origins
WITH user_summary AS (
    SELECT
        user_id,
        CONCAT(INITCAP(home_city), ', ', UPPER(home_country)) AS customer_origin
    FROM users
),
-- Identify flight and hotel bookings
bookings AS (
    SELECT
        s.user_id,
        s.trip_id,
        CASE WHEN s.flight_booked = 'True' THEN 1 ELSE 0 END AS flight_booked,
        CASE WHEN s.hotel_booked = 'True' THEN 1 ELSE 0 END AS hotel_booked
    FROM sessions s
)

-- Analyze travel preferences based on customer origin
SELECT
    us.customer_origin,
    COUNT(DISTINCT b.trip_id) AS total_trips,
    SUM(b.flight_booked) AS total_flight_booked,
    SUM(b.hotel_booked) AS total_hotel_booked
FROM user_summary us
LEFT JOIN bookings b ON us.user_id = b.user_id
GROUP BY 1
ORDER BY total_trips DESC
LIMIT 3

/*
 3.a Analysis Results:
     The top 3 customer origins with the most trips are 
     New York with 279K trips, Los Angeles with 130K trips, and Toronto with 92K trips.
*/

--------------- 4.a Strategic recommendations based on the answers above ------------------

/* 4.a

My recommendation is to:

	1. Focus marketing efforts on male adults and single customers without children. 
	2. When designing travel packages and promotions, factors such as 
           the geographical preferences of customers should be considered, with New York, Los Angeles, and Toronto being the key locations to target. 
	3. Enhancing customer experience, website or app optimization is necessary 
           to minimize session abandonment rates, especially for single customers with children.
     
*/









