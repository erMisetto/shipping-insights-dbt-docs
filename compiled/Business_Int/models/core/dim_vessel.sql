

select
    vessel_imo_number,
    vessel_nme,
    min(voyage_number)         as first_seen_voyage,
    count(distinct voyage_number) as voyages_seen
from BUSINESS_INT_DBT.PUBLIC_staging.stg_shipping_insights
where vessel_imo_number is not null
group by 1,2