

with port_base as (
  -- Collect all origin ports
  select distinct
         origin_port_code as port_code,
         origin_port_city as port_city,
         origin_port_country as port_country,
         'Origin' as port_role
  from BUSINESS_INT_DBT.PUBLIC_staging.stg_shipping_insights
  where origin_port_code is not null

  union all

  -- Collect all destination ports
  select distinct
         dest_port_code as port_code,
         dest_port_city as port_city,
         dest_port_country as port_country,
         'Destination' as port_role
  from BUSINESS_INT_DBT.PUBLIC_staging.stg_shipping_insights
  where dest_port_code is not null
),

-- Deduplicate ports while maintaining role information
port_consolidated as (
  select
    port_code,
    max(port_city) as port_city,
    max(port_country) as port_country,
    array_agg(distinct port_role) as port_roles
  from port_base
  group by port_code
),

-- Join with port coordinates from seed file
ports_with_coordinates as (
  select
    p.port_code,
    p.port_city,
    p.port_country,
    array_to_string(p.port_roles, ', ') as port_roles_list,
    c.latitude,
    c.longitude
  from port_consolidated p
  left join BUSINESS_INT_DBT.PUBLIC_reference_data.port_coordinates c 
    on p.port_code = c.port_code
)

-- Final output with surrogate key
select
    md5(port_code) as port_id,
    port_code,
    port_city,
    port_country,
    port_roles_list,
    latitude,
    longitude,
    current_timestamp() as load_ts
from ports_with_coordinates