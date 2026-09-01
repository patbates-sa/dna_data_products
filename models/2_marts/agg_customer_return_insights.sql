{{ config(materialized="table", transient=false) }}

with customer_insights as (
    select *
    from {{ ref('int_customer_insights') }}
),

customer_returns as (
    select *
    from {{ ref('agg_customer_returns') }}
),

customer_return_base as (
    select
        customer_insights.customer_key,
        coalesce(customer_insights.region, 'unknown') as region,
        coalesce(customer_insights.market_segment, 'unknown') as market_segment,
        coalesce(customer_insights.tier_name, 'unclassified') as tier_name,
        customer_insights.account_balance,
        customer_insights.lifetime_value,
        customer_insights.value_quotient,
        coalesce(customer_returns.total_orders, 0) as total_return_orders,
        coalesce(customer_returns.total_sales_amount, 0) as total_return_sales_amount,
        coalesce(customer_returns.total_orders, 0) > 0 as has_returns
    from customer_insights
    left join customer_returns
        on customer_insights.customer_key = customer_returns.customer_key
),

final as (
    select
        concat_ws('||', region, market_segment, tier_name) as segment_key,
        region,
        market_segment,
        tier_name,
        count(*) as customer_count,
        count_if(has_returns) as returning_customer_count,
        count_if(not has_returns) as customers_without_returns_count,
        count_if(has_returns)::float / nullif(count(*), 0) as pct_customers_with_returns,
        avg(account_balance) as avg_account_balance,
        avg(lifetime_value) as avg_lifetime_value,
        avg(value_quotient) as avg_value_quotient,
        sum(total_return_orders) as total_return_orders,
        sum(total_return_sales_amount) as total_return_sales_amount,
        avg(total_return_orders) as avg_return_orders_per_customer,
        avg(total_return_sales_amount) as avg_return_sales_amount_per_customer,
        sum(total_return_sales_amount) / nullif(count_if(has_returns), 0) as avg_return_sales_amount_per_returning_customer,
        corr(account_balance, total_return_orders) as corr_account_balance_to_return_orders,
        corr(account_balance, total_return_sales_amount) as corr_account_balance_to_return_sales_amount,
        corr(lifetime_value, total_return_orders) as corr_lifetime_value_to_return_orders,
        corr(lifetime_value, total_return_sales_amount) as corr_lifetime_value_to_return_sales_amount,
        corr(value_quotient, total_return_orders) as corr_value_quotient_to_return_orders,
        corr(value_quotient, total_return_sales_amount) as corr_value_quotient_to_return_sales_amount
    from customer_return_base
    group by 1, 2, 3, 4
)

select *
from final
