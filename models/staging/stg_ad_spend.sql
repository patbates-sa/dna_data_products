{{
    config(
        materialized='table'
    )
}}

select 
    id as advertiser_id
    , spend
from {{ source('ads', 'ad_spend') }}
