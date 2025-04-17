{{
  config(
    materialized         = 'incremental',
    unique_key           = 'leg_sk',
    cluster_by           = ['departure_port_code','leg_departure_date'],
    partition_by         = {'field': 'leg_departure_date', 'data_type': 'date'},
    incremental_strategy = 'merge'
  )
}}

with src as (

    select *
    from {{ ref('stg_shipping_insights') }}

    {% if is_incremental() and not flags.FULL_REFRESH %}
      where entry_tme > (select max(entry_tme) from {{ this }})
    {% endif %}

)

select
    shipment_sk,
    shipment_unique_key,
    container_nbr,
    1                                   as leg_sequence,

    origin_port_code                    as departure_port_code,
    dest_port_code                      as arrival_port_code,

    vessel_departure_tme                as actual_departure_tme,
    vessel_arrival_tme                  as actual_arrival_tme,
    est_departure_tme,
    est_arrival_tme,

    arrival_delay_hours,
    departure_delay_hours,
    transshipment_cnt,
    is_transshipped,

    date(vessel_departure_tme)          as leg_departure_date,
    date_trunc('month', vessel_departure_tme::timestamp) as first_departure_month,
    date(vessel_arrival_tme)            as leg_arrival_date,

    voyage_number,
    vessel_nme,
    vessel_imo_number,

    md5(shipment_sk || '|' ||
        origin_port_code || '|' ||
        dest_port_code  || '|' ||
        coalesce(vessel_departure_tme::string,''))  as leg_sk,

    current_timestamp()                 as load_ts
from src
