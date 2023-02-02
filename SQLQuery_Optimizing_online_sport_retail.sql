USE [internation_debt]
GO

SELECT [product_name]
      ,[product_id]
      ,[description]
  FROM [dbo].[info_desc]

GO
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

-- Create label for products group by price range and brand.
SELECT b.brand,
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
	   GROUP BY b.brand
	   ORDER BY total_revenue DESC;

-- Calculate the average discount offered by brand.
SELECT b.brand,
	   AVG(f.discount)*100 AS average_discount
FROM retail_sport_brand AS b
INNER JOIN finance AS f
	  ON b.product_id = f.product_id
GROUP BY b.brand
HAVING brand IS NOT NULL
ORDER BY average_discount;

-- Checked the strength and direction of a correlation between revenue and reviews.
-- Calculate the correlation between reviews and revenue.

SELECT Correlation = (COUNT(*) * SUM(rating_review.reviews* f.revenue) - (SUM(rating_review.reviews)*SUM(f.revenue)))/
					  (SQRT(COUNT(*) * SUM(rating_review.reviews * rating_review.reviews) - (SUM(rating_review.reviews)*SUM(rating_review.reviews))
					  * SQRT(COUNT(*) * SUM(f.revenue * f.revenue) -(SUM(f.revenue)*SUM(f.revenue)))

FROM rating_review 
    INNER JOIN finance
	ON rating_review.product_id = f.product_id;

--The length of product's description might influence a product's rating and reviews
-- Split description into bins in increments of one hundred characters, and calculate
-- average rating by each bin
SELECT CEILING(LEN(i.description)) as description_length,
	   ROUND(AVG(r.rating),2) as average_rating
FROM info_desc as i
INNER JOIN rating_review as r
		ON i.product_id = r.product_id
WHERE i.description IS NOT NULL
GROUP BY description_length
ORDER BY description_length;

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
    AND DATEPART(month,  t.last_visited) IS NOT NULL
ORDER BY b.brand,
		 month;

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
            --percentile_disc(0.5) WITHIN GROUP (ORDER BY revenue)
			--OVER(PARTITION BY description) as median_footwear_revenue
    FROM footwear;

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




            
