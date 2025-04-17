

select distinct
       origin_port_code as port_code,
       origin_port_city as port_city,
       origin_port_country as port_country,
       'Origin' as port_role
from BUSINESS_INT_DBT.PUBLIC_staging.stg_shipping_insights

union all

select distinct
       dest_port_code   as port_code,
       dest_port_city   as port_city,
       dest_port_country as port_country,
       'Destination'    as port_role
from BUSINESS_INT_DBT.PUBLIC_staging.stg_shipping_insights