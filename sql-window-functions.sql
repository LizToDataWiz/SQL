-- Learning WINDOW FUNCTIONS | Advanced SQL
-- source: Data With Mo

-- 1. OVER() - displays the overall avg price in each row
-- calculate the average price with OVER
SELECT
  listing_url,
  host_name,
  room_type,
  price,
  ROUND(AVG(price) OVER(),2) as avg_price
FROM `extreme-battery-403723.airbnb_TO.airbnb-TO`
ORDER BY price;

-- average, min, and max price with OVER
SELECT
  listing_url,
  host_name,
  room_type,
  price,
  ROUND(AVG(price) OVER(),2) as avg_price,
  ROUND(MIN(price) OVER(),2) as min_price,
  ROUND(MAX(price) OVER(),2) as max_price
FROM `extreme-battery-403723.airbnb_TO.airbnb-TO`
order by price desc;

-- 2. PARTITION BY - grouping by within the OVER clause
-- partition by neighbourhood group
SELECT
  listing_url,
  host_name,
  room_type,
  price,
  neighbourhood,
  AVG(price) OVER(PARTITION BY neighbourhood) as avg_price_by_neighbourhood
FROM `extreme-battery-403723.airbnb_TO.airbnb-TO`;

-- partition by neighbourhood, neighbourhood_cleansed
SELECT
  listing_url,
  host_name,
  room_type,
  price,
  neighbourhood,
  neighbourhood_cleansed,
  ROUND(AVG(price) OVER(PARTITION BY neighbourhood),2) as avg_price_by_neighbourhood,
  ROUND(AVG(price) OVER(PARTITION BY neighbourhood, neighbourhood_cleansed),2) as avg_price_by_n_cleansed
FROM `extreme-battery-403723.airbnb_TO.airbnb-TO`;

-- 3. ROW_NUMBER
-- overall price rank
SELECT
  listing_url,
  host_name,
  price,
  row_number() over(order by price desc) as overall_price_rank
FROM `extreme-battery-403723.airbnb_TO.airbnb-TO`;

-- neighbourhood price rank
SELECT
  listing_url,
  host_name,
  price,
  neighbourhood,
  ROW_NUMBER() OVER(ORDER BY price DESC) as overall_price_rank,
  ROW_NUMBER() OVER(PARTITION BY neighbourhood ORDER BY price DESC) as neighbourhood_price_rank
FROM `extreme-battery-403723.airbnb_TO.airbnb-TO`;

-- TOP 3 within each of the neighbourhood
SELECT
  listing_url,
  host_name,
  price,
  ROW_NUMBER() OVER(ORDER BY price DESC) as overall_price_rank,
  ROW_NUMBER() OVER(PARTITION BY neighbourhood ORDER BY price DESC) as neighbourhood_price_rank,
  CASE WHEN ROW_NUMBER() OVER(PARTITION BY neighbourhood ORDER BY price DESC) <= 3 THEN 'Yes'
    ELSE 'No' end as Top_3_flag
FROM `extreme-battery-403723.airbnb_TO.airbnb-TO`;

-- 4. RANK
SELECT
  id,
  host_name,
  neighbourhood,
  neighbourhood_cleansed,
  price,
  ROW_NUMBER() OVER(ORDER BY price DESC) as overall_price_rank,
  RANK() OVER(ORDER BY price DESC) AS overall_pricerank_withRank,
  ROW_NUMBER() OVER(PARTITION BY neighbourhood ORDER BY price DESC) as neighbourhood_price_rank,
  RANK() OVER(PARTITION BY neighbourhood ORDER BY price DESC) AS neigh_priceRank_withRank,
  CASE WHEN ROW_NUMBER() OVER(PARTITION BY neighbourhood ORDER BY price DESC) <= 3 THEN 'Yes'
    ELSE 'No' end as Top_3_flag
FROM `extreme-battery-403723.airbnb_TO.airbnb-TO`;

-- 5. DENSE RANK
-- the results will show the difference between ROW_NUMBER, RANK, and DENSE_RANK
with cte as (
SELECT
  id,
  host_name,
  neighbourhood,
  neighbourhood_cleansed,
  price,
  ROW_NUMBER() OVER(ORDER BY price DESC) as overall_price_rank,
  RANK() OVER(ORDER BY price DESC) as overall_price_rank_withRank,
  DENSE_RANK() OVER(ORDER BY price DESC) AS overall_pricerank_withDenseRank,
FROM `extreme-battery-403723.airbnb_TO.airbnb-TO`
)
SELECT
  host_name,
  neighbourhood,
  price,
  overall_price_rank,
  overall_price_rank_withRank,
  overall_pricerank_withDenseRank
FROM cte
WHERE overall_price_rank <= 10
ORDER BY overall_price_rank;

-- 6. LAG - it will bring in the previous value
--    LAG() requires the OVER clause. 
--    With LAG(), you must specify an ORDER BY in the OVER clause, with a column or a list of columns by which the rows should be sorted.

SELECT
  host_name,
  neighbourhood,
  price,
-- LAG 1 period
  LAG(price) OVER(PARTITION BY host_name ORDER BY price) as previous_price
FROM `extreme-battery-403723.airbnb_TO.airbnb-TO`;

-- LAG 2 period
SELECT
  host_name,
  neighbourhood,
  price,
  LAG(price,2) OVER(PARTITION BY host_name ORDER BY price) as previous_price
FROM `extreme-battery-403723.airbnb_TO.airbnb-TO`;

-- LEAD is the opposite of LAG
-- it brings in the next value

SELECT
  host_name,
  neighbourhood,
  price,
  LEAD(price) OVER(PARTITION BY host_name ORDER BY price) as previous_price
FROM `extreme-battery-403723.airbnb_TO.airbnb-TO`;


-- TOP 3 with subquery to only select the 'YES' values in the top_3_flag column
SELECT * FROM (
  SELECT
    listing_url,
    host_name,
    neighbourhood,
    price,
    ROW_NUMBER() OVER(ORDER BY price DESC) as overall_price_rank,
    ROW_NUMBER() OVER(PARTITION BY neighbourhood ORDER BY price DESC) as neighbourhood_price_rank,
    CASE WHEN ROW_NUMBER() OVER(PARTITION BY neighbourhood ORDER BY price DESC) <= 3 THEN 'Yes'
      ELSE 'No' end as Top_3_flag
  FROM `extreme-battery-403723.airbnb_TO.airbnb-TO`
) as a
WHERE Top_3_flag = 'Yes';

-- we can also use CTE (for me, I prefer using this than subquery)
WITH cte as (
 SELECT
    listing_url,
    host_name,
    neighbourhood,
    price,
    ROW_NUMBER() OVER(ORDER BY price DESC) as overall_price_rank,
    ROW_NUMBER() OVER(PARTITION BY neighbourhood ORDER BY price DESC) as neighbourhood_price_rank,
    CASE WHEN ROW_NUMBER() OVER(PARTITION BY neighbourhood ORDER BY price DESC) <= 3 THEN 'Yes'
      ELSE 'No' end as Top_3_flag
  FROM `extreme-battery-403723.airbnb_TO.airbnb-TO`
)
SELECT * FROM cte
WHERE Top_3_flag = 'Yes';













