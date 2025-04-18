
  
    

        create or replace transient table BUSINESS_INT_DBT.PUBLIC_core.dim_origin_port
         as
        (

select
    port_code,
    port_city,
    port_country,
    latitude,
    longitude,
    current_timestamp() as load_ts
from BUSINESS_INT_DBT.PUBLIC_core.dim_port
where port_roles_list like '%Origin%'
        );
      
  