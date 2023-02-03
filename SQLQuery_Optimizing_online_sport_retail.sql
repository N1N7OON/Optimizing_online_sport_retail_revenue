USE [internation_debt]
GO

SELECT [product_name]
      ,[product_id]
      ,[description]
  FROM [dbo].[info_desc]

GO
CREATE TABLE finance (
	product_id varchar(25),
	listing_price float,
	sale_price float,
	discount float,
	revenue float
);

-- Cout the total number of products, along with the number
--of non-missing values in decription, listing_price, and last_visited.
SELECT COUNT(*) as total_rows,
            COUNT(i.description) as count_description,
            COUNT(f.listing_price) as count_listing_price,
            COUNT(t.last_visited) as count_last_visited
FROM info_desc as i
INNER JOIN finance as f
        ON i.product_id = f.product_id
INNER JOIN traffic as t
        ON f.product_id = t.product_id;
/*
total_row   count_description   count_listing_price   count_last_visited
  3178          3178              3178                   3178
*/

-- Find out how listing_price varies between Addidas and Nike product.
-- We will run a query to produce a distribution of the listing_price
-- and the count for each price, grouped by brand.
SELECT b.brand,
	   CAST(f.listing_price AS integer) AS listing_price,
	   COUNT(*) AS count_product
FROM finance as f

INNER JOIN retail_sport_brand as b
		ON f.product_id = b.product_id
WHERE listing_price > 0
GROUP BY b.brand, f.listing_price
ORDER BY listing_price DESC;

/*
brand    listing_price    count_product
Adidas      300                2
Adidas      280				   4
Adidas      240				   5
Adidas      230				   8
Adidas      220				   11
Nike        200				   1
Adidas		200				   8
Nike		190				   2
Adidas		190				   7
Nike		180				   4
...         ...               ...
*/

-- Create label for products group by price range and brand.
SELECT b.brand, f.listing_price,
       COUNT(*) as count_product,
	   SUM(revenue) AS total_revenue,
	   CASE WHEN f.listing_price < 42 THEN 'Budget'
			WHEN f.listing_price >= 42 and f.listing_price < 74 THEN 'Average'
			WHEN f.listing_price >=74 and f.listing_price < 129 THEN 'Expensive'
			ELSE 'Elite' 
			END AS price_category
FROM finance AS f
INNER JOIN retail_sport_brand AS b
	  ON f.product_id = b.product_id
WHERE b.brand IS NOT NULL
GROUP BY b.brand, f.listing_price
ORDER BY total_revenue DESC;

/*
brand   listing_price   count_product  total_revenue    price_category
Adidas    79.99				322		   1500530.45849      Expensive
Adidas    129.99			96		    806276.78219       Elite
...		   ...				 ...		 ...				...
Adidas     49.99			183          544876.9183      Average
...        ...               ...         ...                ...
Nike      129.95             12          45381.24963       Elite
Nike      159.95			 31          40165.79978       Elite
...        ...               ...          ...               ...
*/

-- Calculate the average discount offered by brand.
SELECT b.brand,
	   AVG(f.discount)*100 AS average_discount
FROM retail_sport_brand AS b
INNER JOIN finance AS f
	  ON b.product_id = f.product_id
GROUP BY b.brand
HAVING brand IS NOT NULL
ORDER BY average_discount;
/*
    brand    averge_discount
	 Nike       0.0
	Adidas     33.452427
*/

-- Checked the strength and direction of a correlation between revenue and reviews.
-- Calculate the correlation between reviews and revenue.

SELECT Correlation = (COUNT(*) * SUM(rating_review.reviews* f.revenue) - (SUM(rating_review.reviews)*SUM(f.revenue)))/
					  (SQRT(COUNT(*) * SUM(rating_review.reviews * rating_review.reviews) - (SUM(rating_review.reviews)*SUM(rating_review.reviews))
					  * SQRT(COUNT(*) * SUM(f.revenue * f.revenue) -(SUM(f.revenue)*SUM(f.revenue)))

FROM rating_review 
    INNER JOIN finance as f
	ON rating_review.product_id = f.product_id;

WITH review_revenue AS (
	   SELECT f.revenue,
			  r.reviews
	   FROM finance as f
	   INNER JOIN rating_review as r
	   ON f.product_id = r.product_id
)

SELECT (
	   (
			SUM(f.revenue * r.reviews) - 
			SUM(f.revenue)* SUM(r.reviews)/COUNT(*)
		)/(
		    SQRT( SUM(f.revenue * f.revenue) - 
			       SUM(f.revenue) * SUM(f.revenue)/COUNT(*)
		        ) * SQRT(
				    SUM(r.reviews * r.reviews) -
					SUM(r.reviews) * SUM(r.reviews)/COUNT(*)

					 )
	   ) ) AS Correlation
FROM review_revenue;
/*
	review_revenue_corr
	  0.651851228
*/

--The length of product's description might influence a product's rating and reviews
-- Split description into bins in increments of one hundred characters, and calculate
-- average rating by each bin
SELECT ROUND(LEN(i.description),2) as description_length,
	   ROUND(AVG(r.rating),2) as average_rating
FROM info_desc as i
INNER JOIN rating_review as r
		ON i.product_id = r.product_id
WHERE i.description IS NOT NULL
GROUP BY description_length
ORDER BY description_length;

/*
	 description_length     average_rating
	      0                     1.87
		100						3.21
		200						3.27
		300						3.29
		400					    3.32
		500						3.12
		600						3.65
*/

-- Count the number of review per brand per month.
SELECT b.brand,
	   DATEPART(month, t.last_visited) as month,
	   COUNT(r.product_id) as num_reviews
FROM traffic as t
INNER JOIN rating_review as r
		ON t.product_id = r.product_id
INNER JOIN retail_sport_brand as b
		ON r.product_id = b.product_id
GROUP BY b.brand, month
HAVING b.brand IS NOT NULL
    AND DATEPART(month,  t.last_visited) IS NOT NULL
ORDER BY b.brand,
		 month;
/*
brand	month	num_reviews
Adidas	1.0	       253
Adidas	2.0	       272
Adidas	3.0	       269
Adidas	4.0	       180
Adidas	5.0	       172
Adidas	6.0	       159
Adidas	7.0	       170
Adidas	8.0	       189
Adidas	9.0	       181
Adidas	10.0	   192
Adidas	11.0	   150
Adidas	12.0	   190
Nike	1.0	        52
Nike	2.0	        52
Nike	3.0	        55
Nike	4.0	        42
Nike	5.0	        41
Nike	6.0	        43
Nike	7.0	        37
Nike	8.0	        29
Nike	9.0	        28
Nike	10.0	    47
Nike	11.0	    38
Nike	12.0	    35
*/

-- Create the footwear CTE, then calculate the number of products and
-- average revenue from these items.
WITH footwear AS
            ( 
                SELECT
                i.description, f.revenue
                FROM info_desc as i
                INNER JOIN finance as f
                        ON i.product_id = f.product_id
                    WHERE i.description LIKE '%shoe%'
                    OR    i.description  LIKE  '%trainer%'
                    OR    i.description  LIKE  '%foot%'
                    AND   i.description IS NOT NULL
            )
    
    SELECT  COUNT(*) as  num_footwear_products,
			AVG(revenue) as average_revenue
           -- percentile_disc(0.5) WITHIN GROUP (ORDER BY revenue)
		   --OVER(PARTITION BY description) as median_footwear_revenue
    FROM footwear;
/*
	 num_footwear_product     average_revenue
		2700                     4235.46138
*/

-- Count clothing product for each brand by creating footwear CTE
-- then use a filter to return only products that are not in the CTE
WITH footwear AS
            ( 
                SELECT
                i.description, f.revenue
                FROM info_desc as i
                INNER JOIN finance as f
                        ON i.product_id = f.product_id
                WHERE i.description LIKE '%shoe%'
                    OR   i.description  LIKE  '%trainer%'
                    OR   i.description  LIKE  '%foot%'
                    AND  i.description IS NOT NULL
            )
    
SELECT  COUNT(*) as  num_clothing_products,
		AVG(f.revenue) as clothe_average_revenue
            --percentile_disc(0.5) WITHIN GROUP (ORDER BY f.revenue) 
			--OVER(PARTITION BY [description]) as median_clothing_revenue
FROM info_desc as i
    INNER JOIN finance as f
            ON i.product_id = f.product_id
WHERE  i.description NOT IN   (SELECT description FROM footwear);

/*
	 num_clothing_product     clothe_average_revenue
		479                      1864.627953
*/


            
