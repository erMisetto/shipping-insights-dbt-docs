{{ 
  config(
    materialized='incremental',
    unique_key='shipment_unique_key',
    cluster_by=['dest_port_code', 'est_arrival_tme::date']
  ) 
}}

with src as (

  select
    shipment_unique_key,
    container_nbr,
    shipment_type,
    shipment_status,
    voyage_number,
    transshipment_cnt,

    -- Shipper details
    shipper_nme,
    shipper_exchange_name,
    shipper_ticker,
    shipper_duns,
    shipper_address,
    shipper_city_nme,
    shipper_state_nme,
    shipper_postal_code,
    shipper_country_nme,
    shipper_phone_nbr,
    shipper_sic4,

    -- Requester details
    requester_nme,
    requester_exchange_name,
    requester_ticker,
    requester_duns,
    requester_address,
    requester_city_nme,
    requester_state_nme,
    requester_postal_code,
    requester_country_nme,
    requester_phone_nbr,
    requester_sic4,

    -- Secondary notify party
    second_notify_party_nme,
    second_notify_party_exchange_name,
    second_notify_party_ticker,
    second_notify_party_duns,
    second_notify_party_address,
    second_notify_party_city_nme,
    second_notify_party_state_nme,
    second_notify_party_postal_code,
    second_notify_party_country_nme,
    second_notify_party_phone_nbr,
    second_notify_party_sic4,

    -- Tertiary notify party
    third_notify_party_nme,
    third_notify_party_exchange_name,
    third_notify_party_ticker,
    third_notify_party_duns,
    third_notify_party_address,
    third_notify_party_city_nme,
    third_notify_party_state_nme,
    third_notify_party_postal_code,
    third_notify_party_country_nme,
    third_notify_party_phone_nbr,
    third_notify_party_sic4,

    -- Port of Receipt (Pickup) details
    plor_unlocode,
    plor_city_nme,
    plor_country_nme,
    plor_est_departure_tme,

    -- Standardized port codes for analytics
    departure_port_unlocode   as origin_port_code,
    departure_port_city_nme   as origin_port_city,
    departure_port_country_nme as origin_port_country,

    destination_port_unlocode   as dest_port_code,
    destination_port_city_nme    as dest_port_city,
    destination_port_country_nme as dest_port_country,

    -- Estimated vs actual timings
    est_departure_tme,
    est_arrival_tme,

    -- Vessel & voyage details
    vessel_nme,
    vessel_imo_number,
    vessel_load_tme,
    vessel_departure_tme,
    vessel_unload_tme,
    vessel_arrival_tme,

    -- Container return timestamp
    return_tme,

    -- Computed delay metrics (in hours)
    timestampdiff(second, est_arrival_tme, vessel_arrival_tme)    / 3600.0 as arrival_delay_hours,
    timestampdiff(second, est_departure_tme, vessel_departure_tme)/ 3600.0 as departure_delay_hours,

    -- Transshipment flag
    case when transshipment_cnt > 0 then true else false end as is_transshipped,

    -- Surrogate key for joins
    md5(shipment_unique_key || container_nbr) as shipment_sk,

    -- Load timestamp for incremental logic
    entry_tme

  from {{ source('dnb_shipping_insights', 'shipments_raw') }}

  {% if is_incremental() and not flags.FULL_REFRESH %}
    where entry_tme > (select max(entry_tme) from {{ this }})
  {% endif %}

)

select * from src
