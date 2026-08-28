{{
    config(
        materialized='table'
    )
}}
--introducing a code change to force a CI build
select 
    id as advertiser_id
    , spend
from {{ source('ads', 'ad_spend') }}


