select
    customer_key,
    account_balance,
    lifetime_value,
    value_quotient,
    account_balance / nullif(lifetime_value, 0) as expected_value_quotient
from {{ ref('int_customer_insights') }}
where (
    lifetime_value is null
    and value_quotient is not null
) or (
    lifetime_value = 0
    and value_quotient is not null
) or (
    lifetime_value is not null
    and lifetime_value != 0
    and (
        value_quotient is null
        or abs(value_quotient - (account_balance / lifetime_value)) > 0.000001
    )
)
