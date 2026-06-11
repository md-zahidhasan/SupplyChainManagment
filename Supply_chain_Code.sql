
-- table create

drop table if exists supply_chain cascade;
CREATE TABLE supply_chain (
    
	product_type VARCHAR(50),
    sku VARCHAR(50),
    price DECIMAL(10,2),
	availability INT,
	number_of_products_sold INT,
    revenue_generated DECIMAL(12,2),
    customer_demographics VARCHAR(50),
	stock_levels INT,
	lead_times INT,
    order_quantities INT,
    shipping_times INT,
	supplier_name VARCHAR(100),
    shipping_costs DECIMAL(10,2),
    shipping_carriers VARCHAR(50),
    location VARCHAR(50),
    lead_time INT,
    production_volumes INT,
    manufacturing_lead_time INT,
    manufacturing_costs DECIMAL(10,2),
    inspection_results VARCHAR(50),
    defect_rates DECIMAL(10,2),
    transportation_modes VARCHAR(50),
    routes VARCHAR(100),
    costs DECIMAL(12,2)
);

select * from supply_chain
limit 10;

alter table supply_chain
rename shipping_carrier to shipping_carriers;
alter table supply_chain
rename shipping_carriers to supplier_name;


--- Business Questions -----

/*  Which product type earns the most revenue? Which SKUs drive sales? Is price related to revenue?*/

--1.total revenue

select sum(revenue_generated) as total_revenue
from supply_chain

-- revenue share % by each profuct type
select product_type,
sum(revenue_generated) as revenue,
round(100 * sum(revenue_generated) /
sum(sum(revenue_generated)) over(),2) as revenue_share_pct
from supply_chain
group by product_type
order by revenue desc;

--- top 10 revenue skus
select sku, revenue_generated from supply_chain
order by revenue_generated desc
limit 10;

--- bottom 10 revenue skus
select sku, revenue_generated from supply_chain
order by revenue_generated asc
limit 10;

--- revenue per unit [revenue by selling each unit products]
select sku, revenue_generated,number_of_products_sold,
round(revenue_generated/nullif(number_of_products_sold,0)) as revenue_per_unit
from supply_chain

--Average Price by Product Type
select product_type,round(avg(price),2) as avg_price
from supply_chain
group by product_type;

--Most Expensive Products
select sku,product_type,price from supply_chain
order by price desc
limit 10;

--Revenue Ranking
select sku, revenue_generated,
rank() over(order by revenue_generated desc) as revenue_rank
from supply_chain
-- Revenue Segmentation[ on the basis of revenue categorize top,mid,low performer]
select sku,revenue_generated,
ntile(4) over(order by revenue_generated desc) as revenue_segment
from supply_chain

/*  Which SKUs face stockout risk? Which products are overstocked? Does ordering match demand? */

-- Current Inventory Position

select sku, stock_levels, order_quantities, number_of_products_sold
from supply_chain;

--Inventory Turnover Ratio
select sku,
round(number_of_products_sold /nullif(stock_levels,0),2) as turnover_ratio
FROM supply_chain;

--Stock Coverage Days
select sku,
round( stock_levels/nullif(number_of_products_sold,0),2) as stock_coverage_days
FROM supply_chain;

--Stockout Risk Flag
select sku,stock_levels,
case
when stock_levels < 40 then 'Stockout Risk'
else 'In Stock'
end as stock_flag
from supply_chain;

--Overstock Flag
select sku,stock_levels,
case
when stock_levels > 90 then 'Overstock'
else 'Normal'
end as inventory_status
from supply_chain;

--Demand vs Order Variance
select sku,number_of_products_sold, order_quantities,
order_quantities - number_of_products_sold as variance
from supply_chain;

--Inventory by Product Type
select product_type,
sum(stock_levels) as stock
from supply_chain
group by product_type;

--Inventory by City
select location,
sum(stock_levels) as stock
from supply_chain
group by location;

--Highest Inventory SKUs
select sku,stock_levels from supply_chain
order by stock_levels desc
limit 10;
--Lowest Inventory SKUs
select sku,stock_levels from supply_chain
order by stock_levels asc
limit 10;

/*  Which supplier has the highest defect rate? Which supplier performs best? Is lead time linked to quality? */

--Average Lead Time by Supplier
select supplier_name,
round(avg(lead_time),2) as avg_lead_time
from supply_chain
group by supplier_name;

--Average Defect Rate by Supplier
select supplier_name,
round(avg(defect_rates),2) as defect_rate
from supply_chain
group by supplier_name;

--Highest Defect Supplier
select supplier_name,
round(avg(defect_rates),2) as defect_rate
from supply_chain
group by supplier_name
order by defect_rate desc
limit 1;
--Lowest Defect Supplier
select supplier_name,
round(avg(defect_rates),2) as defect_rate
from supply_chain
group by supplier_name
order by defect_rate asc
limit 1;

--Inspection Pass Rate
select supplier_name,
round(100 * sum(
case
when inspection_results = 'Pass' then 1 
else 0
end)/count(*),2)
as pass_rate
from supply_chain
group by supplier_name;

--Inspection Result Summary
select inspection_results,count(*) as total
from supply_chain
group by inspection_results;

--Lead Time vs Defect Rate
select supplier_name,
round(avg(lead_time),2) as lead_time,
round(avg(defect_rates),2) as defect_rate
from supply_chain
group by supplier_name;

--Supplier Ranking
select supplier_name,
round(avg(defect_rates),2) as defect_rate,
rank() over(
order by round(avg(defect_rates),2)
) as supplier_rank
from supply_chain
group by supplier_name;

--Supplier Performance Scorecard
select supplier_name,
round(avg(lead_time),2) as lead_time,
round(avg(defect_rates),2) as defect_rate,
count(*) as product_supplied
from supply_chain
group by supplier_name;

--Which carrier is most efficient? Which route costs the most? How much revenue is consumed by shipping?--

--Average Shipping Cost by Carrier
select shipping_carriers,
round(avg(shipping_costs),2) as avg_cost
from supply_chain
group by shipping_carriers;

--Average Shipping Time by Carrier
select shipping_carriers,
round(avg(shipping_times),1) as avg_days
from supply_chain
group by shipping_carriers;

--Best Carrier
select shipping_carriers,
round(avg(shipping_costs),2) as avg_cost,
round(avg(shipping_times),1) as avg_days
from supply_chain
group by shipping_carriers
order by avg_cost,avg_days;

--Cost by Route
select routes,
sum(shipping_costs) as route_cost
from supply_chain
group by routes
order by route_cost desc;

--Most Expensive Route
select routes,
sum(shipping_costs) as route_cost
from supply_chain
group by routes
order by route_cost desc
limit 1;

--Transportation Mode Analysis
select transportation_modes,
round(avg(shipping_costs),2) as avg_cost
from supply_chain
group by transportation_modes;

--Shipping Cost % Revenue

select sku,
round(100 * shipping_costs/nullif(revenue_generated,0),2) as shipping_cost_perProduct
from supply_chain

--Total Logistics Cost
select sum(shipping_costs) as logistics_cost
from supply_chain

--Cost Efficiency Ratio
select sku,
round(revenue_generated/nullif(shipping_costs,0),2) as cost_efficiency_ratio
from supply_chain;

-- Carrier Ranking
select shipping_carriers,
round(avg(shipping_costs),2) as avg_cost,
round(avg(shipping_times),1) as avg_days,
rank() over(
order by round(avg(shipping_costs),2),round(avg(shipping_times),1)) as carrier_rank
from supply_chain
group by shipping_carriers;


