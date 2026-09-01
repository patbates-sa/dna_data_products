{{ config(materialized="table", transient=false) }}

with
campaign as (select * from {{ ref("dim_campaigns") }}),

customer as (select * from {{ ref("dna_data_domain", "dim_customers") }}),

final as (
    select
        campaign.campaign_key || '-' || customer.address as contact_key,
        campaign.name as campaign_name,
        campaign.owner as campaign_owner,
        customer.name as customer_name,
        customer.region as customer_region,
        customer.tier_name,
        customer.address as email_address,
        customer.phone_number
    from campaign
    inner join customer on campaign.tier_name = customer.tier_name
)

select *
from final
