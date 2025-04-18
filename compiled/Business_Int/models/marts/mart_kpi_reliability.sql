-- models/marts/mart_kpi_reliability.sql



with legs as (

  select
    shipment_sk,
    departure_port_code     as origin_port_code,
    arrival_port_code       as dest_port_code,

    -- cast the VARCHAR timestamp to a true TIMESTAMP for date_trunc
    cast(actual_departure_tme as timestamp_ntz) as departure_ts,

    arrival_delay_hours,
    transshipment_cnt

  from BUSINESS_INT_DBT.PUBLIC_core.fct_leg_core

),

kpi as (

  select
    date_trunc('month', departure_ts)           as snapshot_month,
    origin_port_code,
    dest_port_code,
    count(distinct shipment_sk)                 as shipment_count,
    100 * avg(case when arrival_delay_hours <= 0 then 1 else 0 end)
                                                as schedule_reliability_pct,
    avg(arrival_delay_hours)                    as avg_arrival_delay_h,
    avg(transshipment_cnt)                      as avg_transshipments,
    max(arrival_delay_hours)                    as worst_delay_h
  from legs
  group by 1, 2, 3

)

select * from kpi