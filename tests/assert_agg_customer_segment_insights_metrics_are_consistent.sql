select
    segment_key,
    customer_count,
    customers_with_lifetime_value_count,
    customers_without_lifetime_value_count,
    high_value_customer_count,
    mid_value_customer_count,
    low_value_customer_count,
    pct_customers_with_lifetime_value,
    pct_customers_without_lifetime_value,
    pct_high_value_customers,
    pct_mid_value_customers,
    pct_low_value_customers
from {{ ref('agg_customer_segment_insights') }}
where customer_count != customers_with_lifetime_value_count + customers_without_lifetime_value_count
   or customers_with_lifetime_value_count != high_value_customer_count + mid_value_customer_count + low_value_customer_count
   or abs((pct_customers_with_lifetime_value + pct_customers_without_lifetime_value) - 1) > 0.000001
   or abs((pct_high_value_customers + pct_mid_value_customers + pct_low_value_customers) - pct_customers_with_lifetime_value) > 0.000001
