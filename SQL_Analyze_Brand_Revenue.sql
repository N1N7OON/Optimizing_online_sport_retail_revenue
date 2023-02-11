/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (1000) [product_id]
      ,[listing_price]
      ,[sale_price]
      ,[discount]
      ,[revenue]
  FROM [internation_debt].[dbo].[finance]

-- Find last visited on website reatail sport brand per month
SELECT i.product_name,
       b.brand,
	   DATEPART(month,t.last_visited) as month
FROM info_desc as i
INNER JOIN retail_sport_brand as b
	  ON i.product_id = b.product_id
INNER JOIN traffic as t
      ON b.product_id = t.product_id
WHERE DATEPART(YEAR, t.last_visited) = 2019
 --AND  DATEPART(month, t.last_visited) =1
   AND brand = 'Nike'
ORDER BY last_visited
;

--Find description length of each product have influence on revenue 
SELECT LEN(i.description) as description_length,
	   f.revenue
FROM info_desc as i
INNER JOIN finance as f
ON i.product_id = f.product_id
GROUP BY i.description, f.revenue
HAVING LEN(i.description) > 600
ORDER BY LEN(i.description) DESC;

--Find description length of each product have influence on average rating
SELECT ROUND(LEN(i.description),2)/100 as description_length,
	   ROUND((AVG(CAST(r.rating as numeric))),2) as average_rating
FROM info_desc as i
INNER JOIN rating_review as r
		ON i.product_id = r.product_id
WHERE i.description IS NOT NULL
GROUP BY description 
HAVING ROUND(LEN(i.description),2)/100 =0
ORDER BY description_length;

DECLARE @description INT
SET @description = ROUND(LEN(i.description),2)/100 

--Analyze which product brand is the most popular in each month
SELECT i.product_name,
       b.brand,
	   DATEPART(month, t.last_visited) as month,
	   f.revenue
FROM info_desc as i
INNER JOIN retail_sport_brand as b
      ON i.product_id = b.product_id
INNER JOIN traffic as t
      ON b.product_id = t.product_id
INNER JOIN finance as f
      ON t.product_id = f.product_id
WHERE  DATEPART(month, t.last_visited) =1
  AND  DATEPART(year, t.last_visited) = 2018
  AND  brand = 'Nike'
GROUP BY i.product_name, b.brand, t.last_visited, f.revenue
--HAVING MAX(f.revenue) >1000
ORDER BY f.revenue DESC;


SELECT i.product_name,
       b.brand,
	   DATEPART(month, t.last_visited) as month,
	   f.listing_price,
	   f.sale_price,
	   f.revenue
FROM info_desc as i
INNER JOIN retail_sport_brand as b
      ON i.product_id = b.product_id
INNER JOIN traffic as t
      ON b.product_id = t.product_id
INNER JOIN finance as f
      ON t.product_id = f.product_id
WHERE  DATEPART(month, t.last_visited) =12
  AND  DATEPART(year, t.last_visited) = 2018
  AND  brand = 'Nike'
GROUP BY i.product_name, b.brand, t.last_visited,
         f.listing_price,f.sale_price, f.revenue
--HAVING MAX(f.revenue) >1000
ORDER BY f.revenue DESC;