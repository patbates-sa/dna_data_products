{{
  config(
    materialized = "table"
  )
}}
with ad_spend as (
    select * from {{ ref('stg_ad_spend') }}
)



select
    advertiser_id,
    case when row_number() over (order by advertiser_id) = 1 then 1 else null end as user_id,
    sum(spend) as total_ad_spend
from ad_spend
group by advertiser_id

