# API Performance and Cost Analytics Dashboard

[![Tool: Power BI](https://img.shields.io/badge/Power%20BI-Desktop-F2C811?logo=powerbi&logoColor=black)](#)
[![Database: PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1?logo=postgresql&logoColor=white)](#)
[![DAX](https://img.shields.io/badge/DAX-Data%20Analysis%20Expressions-orange)](#)

## Overview
This repository contains an end-to-end data pipeline, relational data model, and interactive Power BI dashboard designed to monitor API request traffic, user subscription tiers, compute token consumption, inference latency, and operational costs across multiple AI models.

The system analyzes simulated production API logs by executing relational queries and performance profiling in PostgreSQL, followed by star-schema modeling, DAX measure engineering, and interactive visualization in Power BI.

---

## Project Structure
- data/
  - api_logs.csv
  - models.csv
  - users.csv
- sql/
  - ai_platform_metrics.sql
- dashboard/
  - ai_platform_metrics.pbix
- .gitignore
- README.md

---

## Relational Architecture & Database Modeling

The raw operational data is structured into a relational star schema inside PostgreSQL:

- **Dimension Tables:**
  - `users`: Contains `user_id` (PK), `subscription_tier` (Free, Pro, Enterprise), `country`, and `sign_up_date`.
  - `models`: Contains `model_id` (PK), `model_name`, `model_type` (Text, Code, Image, Data), and `cost_per_1k_tokens`.
- **Fact Table:**
  - `api_logs`: Contains `log_id` (PK), foreign keys to users and models, timestamp, `prompt_tokens`, `completion_tokens`, and `latency_ms`.

### SQL Transformations & Profiling (`ai_platform_metrics.sql`)
- **Latency Performance Categorization:** Conditional `CASE WHEN` logic classifies individual API calls into discrete operational bands:
  - `Fast`: < 200 ms
  - `Normal`: 200–500 ms
  - `Slow` (Bottleneck): > 500 ms
- **Cost Aggregation:** Multi-table joins evaluate cumulative platform spend per country:
  $$\text{Cost} = \sum \left( \frac{\text{prompt\_tokens} + \text{completion\_tokens}}{1000} \times \text{cost\_per\_1k\_tokens} \right)$$
- **Heavy-Usage Filtering:** Aggregated token usage identified enterprise workloads and models driving token volumes exceeding 10M tokens.

---

## Power BI & DAX Analytics

The processed relational model was ingested into Power BI to build an executive operations dashboard:

- **Core KPI Cards:**
  - Total Token Consumption
  - No. of API Requests
  - Total Cumulative Cost ($)
  - Average Latency (ms)
  - Bottleneck Rate (% of calls exceeding latency thresholds)
- **Time Intelligence & MoM Trends:**
  - Implemented dynamic DAX measures calculating Month-over-Month (MoM) API request growth and trend indicators mapped against a dedicated Date table.
- **Interactive Visualizations:**
  - Clustered Bar Chart: Cost expenditure distributed by model ID.
  - Donut Chart: API request breakdown by performance band (Fast / Normal / Slow).
  - Matrix / Pivot Breakdown: User-level consumption detailing requests, average latency, and individual cost attribution.
  - Dynamic Slicers: Interactive filtering across time (months) and performance categories.

---

## Getting Started

1. **Database Setup:**
   - Execute `sql/ai_platform_metrics.sql` in PostgreSQL / pgAdmin to create the tables, define check constraints, and run the analytical queries.
2. **Dashboard Review:**
   - Open `dashboard/ai_platform_metrics.pbix` in Power BI Desktop to explore the data model, DAX measures, and visual cross-filtering.