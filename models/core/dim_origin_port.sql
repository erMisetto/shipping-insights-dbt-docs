{{
  config(
    materialized = 'table',
    unique_key   = 'port_code',
    schema       = 'core'
  )
}}

select
    port_code,
    port_city,
    port_country,
    latitude,
    longitude,
    current_timestamp() as load_ts
from {{ ref('dim_port') }}
where port_roles_list like '%Origin%'