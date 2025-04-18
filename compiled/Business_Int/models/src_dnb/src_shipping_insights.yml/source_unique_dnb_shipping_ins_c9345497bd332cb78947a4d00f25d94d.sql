
    
    

select
    shipment_unique_key as unique_field,
    count(*) as n_records

from BUSINESS_INT_DBT.PUBLIC.shipments_raw
where shipment_unique_key is not null
group by shipment_unique_key
having count(*) > 1


