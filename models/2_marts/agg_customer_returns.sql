select 
    customer_key
    , count(distinct order_key) as total_orders
    , sum(gross_item_sales_amount) as total_sales_amount
from {{ ref('dna_data_domain', 'fct_order_items', version=1) }}
where is_return = true
group by 1
order by 1 desc
limit 100
