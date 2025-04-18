-- models/marts/mart_container_trace.sql
{{ 
  config(
    materialized = 'table',
    schema = 'marts',
    cluster_by = ['shipment_unique_key']
  ) 
}}

with leg_details as (
  select
    shipment_unique_key,
    container_nbr,
    leg_sequence,
    departure_port_code,
    arrival_port_code,
    
    -- Timing details
    actual_departure_tme,
    actual_arrival_tme,
    est_departure_tme,
    est_arrival_tme,
    
    -- Delay metrics
    arrival_delay_hours,
    departure_delay_hours,
    
    -- Route details
    voyage_number,
    vessel_nme,
    vessel_imo_number
  from {{ ref('fct_leg_core') }}
),

-- Calculate cumulative delay metrics
delay_accumulation as (
  select
    *,
    sum(departure_delay_hours) over (
      partition by shipment_unique_key 
      order by leg_sequence
      rows between unbounded preceding and current row
    ) as cumulative_departure_delay,
    
    sum(arrival_delay_hours) over (
      partition by shipment_unique_key 
      order by leg_sequence
      rows between unbounded preceding and current row
    ) as cumulative_arrival_delay
  from leg_details
),

-- Enrich with port data
enriched_trace as (
  select
    d.*,
    dp.port_city as departure_port_city,
    dp.port_country as departure_country,
    dp.latitude as departure_latitude,
    dp.longitude as departure_longitude,
    
    ap.port_city as arrival_port_city,
    ap.port_country as arrival_country,
    ap.latitude as arrival_latitude,
    ap.longitude as arrival_longitude,
    
    -- Calculate delay categories for visualization
    case
      when d.arrival_delay_hours > 48 then 'Severe Delay'
      when d.arrival_delay_hours > 24 then 'Moderate Delay'
      when d.arrival_delay_hours > 0 then 'Slight Delay'
      else 'On Time'
    end as delay_category
  from delay_accumulation d
  left join {{ ref('dim_port') }} dp on d.departure_port_code = dp.port_code
  left join {{ ref('dim_port') }} ap on d.arrival_port_code = ap.port_code
)

select 
    *,
    row_number() over (partition by shipment_unique_key order by leg_sequence) as display_order,
    
    -- Create a formatted route label for display
    departure_port_code || ' → ' || arrival_port_code || 
    ' (' || round(arrival_delay_hours, 1) || 'h)' as route_label,
    
    -- Flag high risk legs
    case 
      when arrival_delay_hours > 72 then true
      else false
    end as is_high_risk_leg,
    
    current_timestamp() as load_ts
from enriched_trace