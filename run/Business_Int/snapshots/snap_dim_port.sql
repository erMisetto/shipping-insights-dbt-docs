
      
  
    

        create or replace transient table BUSINESS_INT_DBT.PUBLIC_snapshots.snap_dim_port
         as
        (
    

    select *,
        md5(coalesce(cast(port_code as varchar ), '')
         || '|' || coalesce(cast(to_timestamp_ntz(convert_timezone('UTC', current_timestamp())) as varchar ), '')
        ) as dbt_scd_id,
        to_timestamp_ntz(convert_timezone('UTC', current_timestamp())) as dbt_updated_at,
        to_timestamp_ntz(convert_timezone('UTC', current_timestamp())) as dbt_valid_from,
        
  
  coalesce(nullif(to_timestamp_ntz(convert_timezone('UTC', current_timestamp())), to_timestamp_ntz(convert_timezone('UTC', current_timestamp()))), null)
  as dbt_valid_to
from (
        



select
    port_code,
    port_city,
    port_country
from BUSINESS_INT_DBT.PUBLIC_core.dim_port

    ) sbq



        );
      
  
  