CREATE DATABASE dannys_diner;

USE dannys_diner;

CREATE TABLE sales (
    customer_id VARCHAR(1),
    order_date DATE,
    product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', 1),
  ('A', '2021-01-01', 2),
  ('A', '2021-01-07', 2),
  ('A', '2021-01-10', 3),
  ('A', '2021-01-11', 3),
  ('A', '2021-01-11', 3),
  ('B', '2021-01-01', 2),
  ('B', '2021-01-02', 2),
  ('B', '2021-01-04', 1),
  ('B', '2021-01-11', 1),
  ('B', '2021-01-16', 3),
  ('B', '2021-02-01', 3),
  ('C', '2021-01-01', 3),
  ('C', '2021-01-01', 3),
  ('C', '2021-01-07', 3);

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  (1, 'sushi', 10),
  (2, 'curry', 15),
  (3, 'ramen', 12);

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

Select * From Sales;
Select * From menu;
Select * From members;

-- 1.What is the total amount each customer spent at the restaurant?
Select SUM(Price),Sales.customer_id  From sales
inner join menu on menu.product_id=sales.product_id
group by sales.customer_id ;

-- 2.How many days has each customer visited the restaurant?
Select count(distinct(order_date)),s.customer_id  from sales s 
group by customer_id ;

-- 3.What was the first item from the menu purchased by each customer?
with cte as (select *,dense_rank () over(partition by customer_id order by order_date) as rk 
from sales
inner join menu using(product_id))
select * from cte
where rk=1;

-- 4.	What is the most purchased item on the menu and how many times was it purchased by all customers?
Select menu.product_name,count(sales.product_id) as cnt From sales
inner join menu using(product_id)
group by menu.product_name
order by cnt desc 
limit 1;

-- 5.	Which item was the most popular for each customer?
with cte as (
Select count(product_id) as cnt, product_name, customer_id, dense_rank() Over(partition by customer_id order by count(product_id) desc) as rk
From Sales
inner join menu using(product_id)
group by customer_id, product_name)
Select customer_id, product_name 
From cte
where rk=1;

-- 6.	Which item was purchased first by the customer after they became a member?
with cte as (
Select sales.customer_id, sales.order_date, menu.product_name,members.join_date,dense_rank() 
over(partition by sales.customer_id order by order_date) as rk from sales
inner join menu on menu.product_id = sales.product_id
inner join members on members.customer_id = sales.customer_id
where sales.order_date>=members.join_date
)
select * from cte
where rk=1;

-- 7.Which item was purchased just before the customer became a member?
with cte as (
select sales.customer_id, sales.order_date, menu.product_name,members.join_date,dense_rank() 
over(partition by sales.customer_id order by order_date) as rk from sales
inner join menu on menu.product_id = sales.product_id
inner join members on members.customer_id = sales.customer_id 
where sales.order_date<members.join_date
)
select * from cte 
where rk=1;

-- 8.What are the total items and amount spent for each member before they became a member?
select count(sales.product_id) as cnt , sum(price) as amnt,sales.customer_id  
from sales 
inner join menu on menu.product_id = sales.product_id
inner join members on members.customer_id = sales.customer_id
where sales.order_date < members.join_date
group by sales.customer_id;

-- 9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with table_cte as (
select *,case 
 when product_name='sushi' then price*20
 else price*10
 end as points
from sales 
inner join menu using(product_id)
)
select sum(points) , customer_id from table_cte
group by customer_id;

-- 10.In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
-- not just sushi how many points do customer A and B have at the end of January?

SELECT s.customer_id, sum(m.price *10 * 2) as Points_Earned
from Sales s join menu m on s.product_id = m.product_id
join members me on s.customer_id = me.customer_id
where s.order_date >= me.join_date
group by 1;