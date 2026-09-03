with source as (
    select *
    from {{ ref('dna_data_domain', 'fct_order_items', version=1) }}
),

final as (
    select
        order_item_key,
        order_key,
        order_date,
        customer_key,
        part_key,
        supplier_key,
        order_item_status_code,
        is_return,
        line_number,
        ship_date,
        commit_date,
        receipt_date,
        ship_mode,
        supplier_cost,
        base_price,
        discount_percentage,
        discounted_price,
        tax_rate,
        nation_key,
        order_item_count,
        quantity,
        gross_item_sales_amount,
        discounted_item_sales_amount,
        item_discount_amount,
        item_tax_amount,
        net_item_sales_amount
    from source
)

select *
from final
