with source as (
    select *
    from {{ ref('dna_data_domain', 'dim_customers', version=1) }}
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
        is_low_value
    from source
)

select *
from final
