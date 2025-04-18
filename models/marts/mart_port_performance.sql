-- models/marts/mart_port_performance.sql
{{ 
  config(
    materialized = 'table',
    schema = 'marts',
    cluster_by = ['port_code', 'snapshot_quarter']
  ) 
}}

with quarterly_performance as (
  select
    date_trunc('quarter', cast(actual_departure_tme as timestamp_ntz)) as snapshot_quarter,
    departure_port_code as port_code,
    'Origin' as port_role,
    count(*) as shipment_count,
    avg(departure_delay_hours) as avg_delay_hours,
    median(departure_delay_hours) as median_delay_hours,
    sum(case when departure_delay_hours <= 0 then 1 else 0 end)::float / 
      nullif(count(*), 0) * 100 as on_time_pct
  from {{ ref('fct_leg_core') }}
  where actual_departure_tme is not null
  group by 1, 2, 3
  
  union all
  
  select
    date_trunc('quarter', cast(actual_arrival_tme as timestamp_ntz)) as snapshot_quarter,
    arrival_port_code as port_code,
    'Destination' as port_role,
    count(*) as shipment_count,
    avg(arrival_delay_hours) as avg_delay_hours,
    median(arrival_delay_hours) as median_delay_hours,
    sum(case when arrival_delay_hours <= 0 then 1 else 0 end)::float / 
      nullif(count(*), 0) * 100 as on_time_pct
  from {{ ref('fct_leg_core') }}
  where actual_arrival_tme is not null
  group by 1, 2, 3
),

port_trends as (
  select
    port_code,
    port_role,
    snapshot_quarter,
    shipment_count,
    avg_delay_hours,
    median_delay_hours,
    on_time_pct,
    
    -- Calculate trend metrics over previous quarters
    lag(avg_delay_hours, 1) over (
      partition by port_code, port_role 
      order by snapshot_quarter
    ) as prev_qtr_delay,
    
    lag(avg_delay_hours, 2) over (
      partition by port_code, port_role 
      order by snapshot_quarter
    ) as prev_2qtr_delay,
    
    lag(avg_delay_hours, 3) over (
      partition by port_code, port_role 
      order by snapshot_quarter
    ) as prev_3qtr_delay,
    
    lag(avg_delay_hours, 4) over (
      partition by port_code, port_role 
      order by snapshot_quarter
    ) as prev_year_delay,
    
    -- Calculate Z-score for congestion index (higher is worse)
    (avg_delay_hours - 
      avg(avg_delay_hours) over (
        partition by snapshot_quarter, port_role
      )) / 
      nullif(stddev(avg_delay_hours) over (
        partition by snapshot_quarter, port_role
      ), 0) as congestion_z_score
  from quarterly_performance
),

-- Calculate trend using simple average rate of change over last 3 quarters
trend_calculation as (
  select
    *,
    case
      when prev_3qtr_delay is not null then 
        (avg_delay_hours - prev_3qtr_delay) / 3  -- Average change per quarter over last 3 quarters
      when prev_2qtr_delay is not null then
        (avg_delay_hours - prev_2qtr_delay) / 2  -- Average change per quarter over last 2 quarters
      when prev_qtr_delay is not null then
        (avg_delay_hours - prev_qtr_delay)       -- Change over last quarter
      else null
    end as quarterly_avg_change
  from port_trends
),

port_info as (
  select
    port_code,
    port_city,
    port_country,
    latitude,
    longitude
  from {{ ref('dim_port') }}
)

select
  t.*,
  p.port_city,
  p.port_country,
  p.latitude,
  p.longitude,
  
  -- Calculate quarter-over-quarter change
  (avg_delay_hours - prev_qtr_delay) as qoq_delay_change,
  case when prev_qtr_delay != 0 
       then (avg_delay_hours - prev_qtr_delay) / nullif(abs(prev_qtr_delay), 0) * 100 
       else null 
  end as qoq_delay_pct_change,
  
  -- Calculate year-over-year change
  (avg_delay_hours - prev_year_delay) as yoy_delay_change,
  case when prev_year_delay != 0 
       then (avg_delay_hours - prev_year_delay) / nullif(abs(prev_year_delay), 0) * 100 
       else null 
  end as yoy_delay_pct_change,
  
  -- Performance trend categorization using average change instead of regression slope
  case
    when quarterly_avg_change < -1 then 'Improving'
    when quarterly_avg_change > 1 then 'Deteriorating'
    else 'Stable'
  end as trend_category,
  
  -- Create rank fields for top improving/deteriorating ports
  row_number() over (
    partition by snapshot_quarter, port_role,
    case when quarterly_avg_change < -1 then 1 else 0 end
    order by quarterly_avg_change asc
  ) as improvement_rank,
  
  row_number() over (
    partition by snapshot_quarter, port_role,
    case when quarterly_avg_change > 1 then 1 else 0 end
    order by quarterly_avg_change desc
  ) as deterioration_rank,
  
  current_timestamp() as load_ts
from trend_calculation t
join port_info p on t.port_code = p.port_code