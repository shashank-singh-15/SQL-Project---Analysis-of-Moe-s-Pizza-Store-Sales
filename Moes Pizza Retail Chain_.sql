-- Q1 Retrieve the total number of orders placed --
SELECT 
    COUNT(order_id) as Total_orders
FROM
    orders_time;
    
    

-- Q2 Calculate the total revenue generated from pizza sales --
SELECT 
    ROUND(SUM(pizza_price.price * order_details.quantity),
            1) AS Total_Revenue
FROM
    pizza_price
        JOIN
    order_details ON pizza_price.pizza_id = order_details.pizza_id;
    
    
    
-- Q3 Identify the highest-priced pizza --

select name, category from pizza_types
where pizza_type_id =(select pizza_type_id from pizza_price
order by price desc
limit 1);

-- Alternate Answer --
SELECT 
    types.name, types.category, price.size, price.price
FROM
    pizza_types AS types
        JOIN
    pizza_price AS price
ORDER BY price.price DESC
LIMIT 1;




-- Q4 Identify the most common pizza size ordered --
SELECT 
    pizza_price.size,
    SUM(order_details.quantity) AS Total_orders
FROM
    pizza_price
        JOIN
    order_details ON pizza_price.pizza_id = order_details.pizza_id
GROUP BY pizza_price.size
ORDER BY SUM(order_details.quantity) DESC;




-- Q5 List the top 5 most ordered pizza types along with their quantities --
SELECT 
    pizza_types.name,
    pizza_types.category,
    SUM(order_details.quantity) AS total_quantity_ordered
FROM
    pizza_types
        JOIN
    pizza_price ON pizza_types.pizza_type_id = pizza_price.pizza_type_id
        JOIN
    order_details ON order_details.pizza_id = pizza_price.pizza_id
GROUP BY pizza_types.name , pizza_types.category
ORDER BY SUM(order_details.quantity) DESC
LIMIT 5;




-- Q6 Join the necessary tables to find the total quantity of each pizza category ordered --

SELECT 
    pizza_types.category,
    SUM(order_details.quantity) AS total_quantity_ordered
FROM
    pizza_types
        JOIN
    pizza_price ON pizza_types.pizza_type_id = pizza_price.pizza_type_id
        JOIN
    order_details ON order_details.pizza_id = pizza_price.pizza_id
GROUP BY pizza_types.category
ORDER BY SUM(order_details.quantity) DESC;   





-- Q7. Determine the distribution of orders by hour of the day --
SELECT 
    HOUR(order_time) AS Hour_, COUNT(order_id) AS Order_Count
FROM
    orders_time
GROUP BY HOUR(order_time)
ORDER BY HOUR(order_time);




-- Q8. Join relevant tables to find the category-wise distribution of pizzas --
SELECT 
    pizza_types.category,
    SUM(order_details.quantity) AS quantity_ordered
FROM
    pizza_types
        JOIN
    pizza_price ON pizza_types.pizza_type_id = pizza_price.pizza_type_id
        JOIN
    order_details ON pizza_price.pizza_id = order_details.pizza_id
GROUP BY pizza_types.category
ORDER BY SUM(order_details.quantity) DESC;




-- Q9. (A) Group the orders by date  and  (B) calculate the average number of pizzas ordered per day --

-- Answer 9 (A) --

SELECT 
    orders_time.order_date,
    SUM(order_details.quantity) AS quantity_ordered
FROM
    orders_time
        JOIN
    order_details ON orders_time.order_id = order_details.order_id
GROUP BY orders_time.order_date
ORDER BY orders_time.order_date ASC;

-- Answer 9 (B) --

SELECT 
    ROUND(AVG(quantity_ordered), 1)
FROM
    (SELECT 
        orders_time.order_date,
            SUM(order_details.quantity) AS quantity_ordered
    FROM
        orders_time
    JOIN order_details ON orders_time.order_id = order_details.order_id
    GROUP BY orders_time.order_date
    ORDER BY orders_time.order_date ASC) AS quantity_by_date;
    
    
    
    
    -- Q10. Determine the top 3 most ordered pizza types based on revenue --
    
    SELECT 
    pizza_types.name,
    ROUND(SUM(pizza_price.price * order_details.quantity),
            1) AS revenue
FROM
    pizza_types
        JOIN
    pizza_price ON pizza_types.pizza_type_id = pizza_price.pizza_type_id
        JOIN
    order_details ON order_details.pizza_id = pizza_price.pizza_id
GROUP BY pizza_types.name
ORDER BY revenue DESC
LIMIT 5;
    
    
    
    
    
    -- Q11. Calculate the percentage contribution of each pizza type to total revenue --
	SELECT 
    pizza_types.category,
    ROUND((SUM(pizza_price.price * order_details.quantity) / (SELECT 
                    ROUND(SUM(pizza_price.price * order_details.quantity),
                                1) AS Total_Revenue
                FROM
                    pizza_price
                        JOIN
                    order_details ON pizza_price.pizza_id = order_details.pizza_id) * 100),
            2) AS percent_of_total_revenue
FROM
    pizza_types
        JOIN
    pizza_price ON pizza_types.pizza_type_id = pizza_price.pizza_type_id
        JOIN
    order_details ON order_details.pizza_id = pizza_price.pizza_id
GROUP BY pizza_types.category;







-- Q12. Analyze the cumulative revenue generated over time --

select order_date, round(sum(revenue) over(order by order_date), 1) as cumulative_revenue
from
(SELECT 
    orders_time.order_date,
    SUM(order_details.quantity * pizza_price.price) AS revenue
FROM
    pizza_price
        JOIN
    order_details ON pizza_price.pizza_id = order_details.pizza_id
        JOIN
    orders_time ON order_details.order_id = orders_time.order_id
GROUP BY orders_time.order_date
ORDER BY orders_time.order_date ASC) as revenue_by_date;







-- Q13. Determine the top 3 most ordered pizza types based on revenue for each pizza category --

SELECT category, name, revenue, rnk
FROM (
    SELECT pizza_types.category, pizza_types.name, 
           SUM(order_details.quantity * pizza_price.price) AS revenue,
           RANK() OVER (PARTITION BY pizza_types.category ORDER BY SUM(order_details.quantity * pizza_price.price) DESC) AS rnk
    FROM pizza_types 
    JOIN pizza_price ON pizza_types.pizza_type_id = pizza_price.pizza_type_id 
    JOIN order_details ON order_details.pizza_id = pizza_price.pizza_id
    GROUP BY pizza_types.category, pizza_types.name
) AS ranked_pizzas
WHERE rnk <= 3;






-- Q14. Identify the average quantity of pizzas ordered per order --

SELECT 
    round(AVG(total_quantity), 1) AS avg_pizzas_per_order  
FROM (
    SELECT 
        order_id,                               
        SUM(quantity) AS total_quantity         
    FROM 
        order_details
    GROUP BY 
        order_id                                 
) AS order_totals;







-- Q15. Analyze which combination of pizza size and category has highest contribution to our revenue --

WITH total_revenue_cte AS (
    -- Calculate the total revenue for all orders (grand total)
    SELECT 
        SUM(od.quantity * pp.price) AS grand_total_revenue
    FROM 
        order_details od
    JOIN 
        pizza_price pp ON od.pizza_id = pp.pizza_id
)
SELECT 
    pp.size,                                      -- Pizza size (small, medium, large)
    pt.category,                                  -- Pizza category (chicken, classic, supreme, veggie)
    SUM(od.quantity * pp.price) AS total_revenue, -- Total revenue for each size and category
    ROUND((SUM(od.quantity * pp.price) / (SELECT grand_total_revenue FROM total_revenue_cte)) * 100, 2) AS revenue_percentage -- Calculate revenue percentage
FROM 
    order_details od
JOIN 
    pizza_price pp ON od.pizza_id = pp.pizza_id
JOIN 
    pizza_types pt ON pp.pizza_type_id = pt.pizza_type_id
GROUP BY 
    pp.size, pt.category                          -- Group by pizza size and category
ORDER BY 
    revenue_percentage DESC;                      -- Sort by revenue percentage to find the most profitable combination

                             


    
    
-- Q16. Analyze the trend of orders over time (average order quantities and revenue) --
SELECT 
    orders_time.order_date,                                        -- The date of the order
    AVG(order_details.quantity) AS avg_quantity_per_order,  -- Average quantity of pizzas ordered per order on that date
    SUM(order_details.quantity * pizza_price.price) AS total_revenue, -- Total revenue generated on that date
    AVG(order_details.quantity * pizza_price.price) AS avg_revenue_per_order -- Average revenue per order on that date
FROM 
    order_details
JOIN 
    orders_time ON order_details.order_id = orders_time.order_id -- Join with order_time to get the date of the order
JOIN 
    pizza_price ON order_details.pizza_id = pizza_price.pizza_id -- Join with pizza_price to get the price of the pizza
GROUP BY 
    orders_time.order_date                                         -- Group by date to observe daily trends
ORDER BY 
    orders_time.order_date ASC;                                    -- Order by date to view the trend over time



    
    
    
    