with campaigns as (

    select * from {{ ref('campaigns') }}

),

final as (

    select
        id,
        seq,
        name,
        tier_name,
        owner,
        id || '-' || seq as campaign_key

    from campaigns

)

select * from final
