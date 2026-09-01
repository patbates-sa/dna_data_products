with source as (
    select *
    from {{ ref('stg_dim_customers') }}
),

final as (
    select
        customer_key,
        region,
        name,
        address,
        nation,
        phone_number,
        account_balance,
        market_segment,
        lifetime_value,
        tier_name,
        is_high_value,
        is_mid_value,
        is_low_value,
        account_balance / nullif(lifetime_value, 0) as value_quotient
    from source
)

select *
from final
