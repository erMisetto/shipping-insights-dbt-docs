📦 Shipping Reliability Dashboard (Snowflake + dbt + Tableau)

This E2E pipeline project aims to reduce late container arrivals and costly transshipments in global shipping by showing clear, actionable insights to stakeholders like freight forwarders, carriers, port operators, and insurers.

It uses an end-to-end data pipeline built with:

    Snowflake for data storage and transformation

    dbt Core (with VS Code) for data modeling and testing

    Tableau for interactive dashboards and visual storytelling

🔍 Project Goal

To give businesses early warnings and smart recommendations so they can:

    Avoid congested ports

    Pick more reliable carriers

    Reroute containers in real-time

    Improve scheduling and planning

    
🗂 Project Structure

Business_Int/
├── dbt_project.yml             # dbt project config
├── models/                     # dbt models folder
│   ├── src_dnb/                # Source config (Snowflake seed)
│   ├── staging/                # Cleaned data models
│   ├── core/                   # Fact and dimension tables
│   ├── marts/                  # Business KPIs (e.g. reliability)
│   └── tests/                  # Custom dbt data tests
├── macros/                     # Reusable dbt macros
├── seeds/                      # CSV seed data (e.g. dimension table)
└── snapshots/                  # Slowly Changing Dimension (SCD) snapshot for ports

📊 Dashboard Overview

The Tableau dashboard includes:

    KPI Pulse Board
    See overall on-time %, average delays, and transshipment risks at a glance.

    Delay Heatmap
    Shows how delays have changed over time by year and severity.

    Carrier Scorecard
    Ranks carriers by performance—helpful for contract reviews.

    Port Trend Map
    Maps ports by improvement or congestion trend.

    Container Trace
    Lets users trace shipment legs to find where delays happened.

⚙️ How It Works

    Data is loaded from a Snowflake table (based on a 1,000-row sample).

    dbt transforms and cleans the data, creating metrics and KPIs.

    Tableau connects to the final tables and shows results in a clear way.

    A snapshot tracks changes to port details over time (SCD Type 2).

⚠️ Limitations

This project uses a sample of 1,000 rows. While useful for building and testing, this is not enough to represent real-world patterns.

Once the full dataset (54M+ shipments/month) is available, more accurate and powerful insights can be generated.
📚 Features

    Modular and scalable dbt models

    Clean, human-centered dashboard design

    dbt Docs generated for full data lineage

    Custom data tests for delay logic and transshipment impact

    Incremental models built for performance

📥 How to Run

    Clone the repo
    git clone https://github.com/your-username/shipping-reliability-dbt.git

    Install dbt core (version 1.9+)
    pip install dbt-core dbt-snowflake

    Set up your Snowflake profile in ~/.dbt/profiles.yml

    Run models and snapshots
    dbt run
    dbt snapshot

View my dashboard in Tableau (https://public.tableau.com/app/profile/mattia.bianchi1534/viz/ShippingInsightsDashboardReliabilityDelayandPerformanceTrends/Dashboard1)

👤 Author

Mattia Bianchi
Master’s in Business Analytics
Hult International Business School
April 2025