-- 1. What is the total amount each customer spent at the restaurant?

select
	s.customer_id,
    sum(m.price) as total_spent
from
	dannys_diner.sales as s
    join
    dannys_diner.menu as m on s.product_id= m.product_id
group by
	customer_id;
    
-- 2. How many days has each customer visited the restaurant?

select
	s.customer_id,
    count(distinct s.order_date) as days_of_visiting
from
	sales as s
group by
	1;
    
-- 3. What was the first item from the menu purchased by each customer?

with ranked as (
select
	s.customer_id,
    m.product_name,
    s.order_date,
    row_number() over(partition by s.customer_id order by s.order_date) as row_numbers
from
	sales as s
    join
    menu as m on s.product_id= m.product_id)
    
select * from ranked where row_numbers=1;


-- 4. What is the most purchased item on the menu and how many times has it been purchased by all customers?

with ranked as
(select
	m.product_name,
    count(m.product_name) as total_purchase_quantity,
    row_number() over( order by count(m.product_name) desc) as row_numbers
from
	sales as s
    join
    menu as m on s.product_id = m.product_id
group by
	1)

select * from ranked where row_numbers=1;

-- 5. Which item was the most popular for each customer?

with ranked as (
select
	s.customer_id,
    m.product_name,
    count(m.product_name) as total_purchase_quantity,
    rank() over(partition by s.customer_id order by count(m.product_name) desc) as ranks
from
	sales as s
    join
    menu as m on s.product_id=m.product_id
group by
	1,2)
    
select * from ranked where ranks=1;

-- 6. Which item was purchased first by the customer after they became a member?

WITH ranked AS (
    SELECT
      s.customer_id,
      order_date,
      join_date,
      product_name,
      rank() OVER (
        PARTITION BY s.customer_id
        ORDER BY
          order_date
      ) AS ranks
    FROM
      sales AS s
      JOIN members AS mm ON s.customer_id = mm.customer_id
      JOIN menu AS m ON s.product_id = m.product_id
    WHERE
      order_date >= join_date
  )
SELECT
  customer_id,
  join_date,
  order_date,
  product_name
FROM
  ranked AS r
WHERE
  ranks = 1
ORDER BY
  1;

-- 7. Which item was purchased just before the customer became a member?

WITH ranked AS (
    SELECT
      s.customer_id,
      order_date,
      join_date,
      product_name,
      rank() OVER (
        PARTITION BY s.customer_id
        ORDER BY
          order_date DESC
      ) AS ranks
    FROM
      sales AS s
      JOIN members AS mm ON s.customer_id = mm.customer_id
      JOIN menu AS m ON s.product_id = m.product_id
    WHERE
      order_date < join_date
  )
SELECT
  customer_id,
  join_date,
  order_date,
  product_name
FROM
  ranked AS r
WHERE
  ranks = 1
ORDER BY
  1;

-- 8. What is the total items and amount spent for each member before they became a member?

SELECT
  s.customer_id,
  COUNT(product_name) AS total_number_of_items,
  SUM(price) AS total_purchase_amount
FROM
  sales AS s
  JOIN members AS mm ON s.customer_id = mm.customer_id
  JOIN menu AS m ON s.product_id = m.product_id
WHERE
  order_date < join_date
GROUP BY
  1
ORDER BY
  1;

-- 9.  If each $1 spent equals to 10 points earned and sushi has a 2x points multiplier - how many points would each customer have?

SELECT
  customer_id,
  SUM(point) AS points
FROM
  sales AS s
  JOIN (
    SELECT
      product_id,
      CASE
        WHEN product_id = 1 THEN price * 20
        ELSE price * 10
      END AS point
    FROM
      menu
  ) AS p ON s.product_id = p.product_id
GROUP BY
  1
ORDER BY
  1;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

WITH count_points AS (
    SELECT
      s.customer_id,
      order_date,
      join_date,
      product_name,
      SUM(point) AS point
    FROM
      sales AS s
      JOIN (
        SELECT
          product_id,
          product_name,
          CASE
            WHEN product_name = 'sushi' THEN price * 20
            ELSE price * 10
          END AS point
        FROM
          menu AS m
      ) AS p ON s.product_id = p.product_id
      JOIN members AS mm ON s.customer_id = mm.customer_id
    GROUP BY
      s.customer_id,
      order_date,
      join_date,
      product_name,
      point
  )
SELECT
  customer_id,
  SUM(
    CASE
      WHEN order_date >= join_date
      AND order_date < DATE_ADD(join_date, INTERVAL 7 DAY)
      THEN point * 2
      ELSE point
    END
  ) AS new_points
FROM
  count_points
WHERE
  month(order_date) = 1
GROUP BY
  1
ORDER BY
  1;