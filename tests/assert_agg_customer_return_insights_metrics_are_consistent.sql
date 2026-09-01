select *
from {{ ref('agg_customer_return_insights') }}
where returning_customer_count > customer_count
    or customers_without_returns_count > customer_count
    or returning_customer_count + customers_without_returns_count != customer_count
    or pct_customers_with_returns < 0
    or pct_customers_with_returns > 1
    or total_return_orders < 0
    or total_return_sales_amount < 0
    or abs(corr_account_balance_to_return_orders) > 1
    or abs(corr_account_balance_to_return_sales_amount) > 1
    or abs(corr_lifetime_value_to_return_orders) > 1
    or abs(corr_lifetime_value_to_return_sales_amount) > 1
    or abs(corr_value_quotient_to_return_orders) > 1
    or abs(corr_value_quotient_to_return_sales_amount) > 1
