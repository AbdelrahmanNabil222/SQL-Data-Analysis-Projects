-- change over time 
select 
YEAR(order_date) as order_year,
month(order_date) as order_month,
sum(sales_amount) as total_sales,
count(Distinct(customer_key)) as total_customers,
sum(quantity) as total_quantity
from fact_sales
where order_date is not null
group by year(order_date), month(order_date)
order by year(order_date), month(order_date)
--------------------------------------------------
select 
DATETRUNC(month,order_date) as order_date,
sum(sales_amount) as total_sales,
count(Distinct(customer_key)) as total_customers,
sum(quantity) as total_quantity
from fact_sales
where order_date is not null
group by datetrunc(month,order_date)
order by datetrunc(month,order_date)
---------------------------------------------------
select 
FORMAT(order_date,'yyyy-MMM') as order_date,
sum(sales_amount) as total_sales,
sum(quantity) as total_quantity,
count(Distinct(customer_key)) as total_customers
from fact_sales
where order_date is not null
group by FORMAT(order_date,'yyyy-MMM') 
order by format(order_date,'yyyy-MMM')
----------------------------------------------------
--calculate total sales per month
--and the running total of sales over time
--and moving average price 
select
order_date,
total_sales,
sum(total_sales) over(order by order_date) as running_total_sales,
avg_price,
avg(avg_price) over(order by order_date) as moving_avg_peice
from(
select 
YEAR(order_date) as order_date,
sum(sales_amount) as total_sales,
avg(price) as avg_price
from fact_sales
where order_date is not null
group by year(order_date)
)t
----------------------------------------------------
-- yearly performance of products
With yearly_product_sales as (
select 
year(order_date)as order_date,
product_name,
sum(sales_amount) as current_sales
from dim_products p
full join
fact_sales s on p.product_key=s.product_key 
where order_date is not null
group by year(order_date),product_name
)

select 
order_date,
product_name,
current_sales,
lag(current_sales)over(partition by product_name order by order_date) as pervious_year_sales,
current_sales-LAG(current_sales)over(partition by product_name order by order_date) as diff_pervious_year_sales,
case 
when current_sales-lag(current_sales)over(partition by product_name order by order_date)>0 then 'increase'
when current_sales-lag(current_sales)over(partition by product_name order by order_date)<0 then 'decrease'
else 'no change'
end 'py_change',
avg(current_sales)over(partition by product_name) as avg_sales,
current_sales-avg(current_sales) over(partition by product_name) as diff_avg,
case 
when current_sales-avg(current_sales)over(partition by product_name)>0 then 'above avg'
when current_sales - avg(current_sales)over(partition by product_name)<0 then 'below avg'
else 'avg'
end 'avg change'
from yearly_product_sales 
---------------------------------------------------------
--part to whole
With category_sales as(
select 
p.category,
sum(s.sales_amount) as total_sales
from fact_sales s full join dim_products p on s.product_key=p.product_key
where category is not null and s.sales_amount is not null
group by category
)

select 
category,
total_sales,
sum(total_sales) over() as overall_sales,
concat(cast(total_sales as float)/sum(total_sales)over()*100,'%') as percentage_of_total
from category_sales
group by category,total_sales
order by total_sales desc
----------------------------------------------------------
-- segment product into cost ranges and count how many products fall into eact segment
with products_segment as(
select 
product_id,
product_name,
cost,
case
    when cost<100 then 'below 100'
    when cost between 100 and 500 then '100-500'
    when cost between 500 and 1000 then '500-1000'
    else 'above 1000'
    end 'cost_range'
 from dim_products)

 select 
 cost_range,
 count(product_id) as products_count
 from products_segment
 group by cost_range
 order by products_count desc
 ------------------------------------------------------
 -- customer segment based on their spending behavior and total number of customer by each group

with customer_spending as(
 select 
 c.customer_key,
 sum(s.sales_amount) total_spending,
 DATEDIFF(MONTH,min(order_date),max(order_date)) as lifespan
 from fact_sales s
 left join
 dim_customers c
 on s.customer_key=c.customer_key
 group by c.customer_key
 )

--total number of customer by each group
select 
customers_segment,
count(customer_key) as total_customers
from(
-- customer segment based on their spending behavior
 select
 customer_key,
 total_spending,
 lifespan,
 case
   when lifespan>=12 and total_spending>5000 then 'VIP'
   when lifespan>=12 and total_spending<=5000 then 'Regular'
   else 'New'
   end customers_segment
   from customer_spending
   )t
   group by customers_segment
---------------------------------------------------------
--Base query retrieve core columns from tables
select 
s.order_date,
s.order_number,
s.product_key,
c.customer_key,
CONCAT(c.first_name,' ',c.last_name) as full_name,
c.country,
DATEDIFF(year,c.birthdate,GETDATE()) as age
from fact_sales s
left join 
dim_customers c
on s.customer_key = c.customer_key
where s.order_date is not null
