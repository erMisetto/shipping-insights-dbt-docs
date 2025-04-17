{% snapshot snap_dim_port %}

{{ config(
    target_schema = 'PUBLIC_snapshots',
    unique_key    = 'port_code',
    strategy      = 'check',
    check_cols    = [
        'port_city',
        'port_country'
    ]
) }}

select
    port_code,
    port_city,
    port_country
from {{ ref('dim_port') }}

{% endsnapshot %}
