{{ config(materialized="table", transient=false) }}

with customer_insights as (
    select * from {{ ref('int_customer_insights') }}
),

aggregated as (
    select
        region,
        market_segment,
        count(*) as customer_count,
        sum(case when lifetime_value is not null then 1 else 0 end) as customers_with_lifetime_value_count,
        sum(case when lifetime_value is null then 1 else 0 end) as customers_without_lifetime_value_count,
        sum(case when is_high_value = 'Y' then 1 else 0 end) as high_value_customer_count,
        sum(case when is_mid_value = 'Y' then 1 else 0 end) as mid_value_customer_count,
        sum(case when is_low_value = 'Y' then 1 else 0 end) as low_value_customer_count,
        sum(account_balance) as total_account_balance,
        avg(account_balance) as avg_account_balance,
        coalesce(sum(lifetime_value), 0) as total_lifetime_value,
        avg(lifetime_value) as avg_lifetime_value,
        avg(value_quotient) as avg_value_quotient
    from customer_insights
    group by 1, 2
),

final as (
    select
        region || '-' || market_segment as segment_key,
        region,
        market_segment,
        customer_count,
        customers_with_lifetime_value_count,
        customers_without_lifetime_value_count,
        high_value_customer_count,
        mid_value_customer_count,
        low_value_customer_count,
        total_account_balance,
        avg_account_balance,
        total_lifetime_value,
        avg_lifetime_value,
        avg_value_quotient,
        customers_with_lifetime_value_count::float / nullif(customer_count, 0) as pct_customers_with_lifetime_value,
        customers_without_lifetime_value_count::float / nullif(customer_count, 0) as pct_customers_without_lifetime_value,
        high_value_customer_count::float / nullif(customer_count, 0) as pct_high_value_customers,
        mid_value_customer_count::float / nullif(customer_count, 0) as pct_mid_value_customers,
        low_value_customer_count::float / nullif(customer_count, 0) as pct_low_value_customers
    from aggregated
)

select *
from final
