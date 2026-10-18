# ecommerce-etl-star-schema

End-to-end ETL pipeline: raw e-commerce orders → Pentaho Data Integration → PostgreSQL star schema → BI dashboard.

> **Note:** The dataset is synthetic and was generated for learning purposes. No real customer data is used.

> 📄 **Full project report (Turkish):** [Verinin Yolculuğu – ETL Raporu](docs/Verinin_Yolculugu_ETL_Raporu.pdf)

## Overview

Raw order data is written fast and without validation, so it is full of inconsistencies. This project cleans it with Pentaho PDI, loads it into a star schema in PostgreSQL, validates the load with SQL queries, and visualizes the result in a dashboard built with Data Plato.

```mermaid
flowchart LR
    A[ecommerce_raw_data.csv<br/>510 rows] --> B[Pentaho PDI<br/>clean + transform]
    B --> C[(PostgreSQL 16<br/>star schema)]
    C --> D[Data Plato<br/>dashboard]
```

The setup uses two VMs on the same network:

- **VM1 (db-server):** PostgreSQL 16 and pgAdmin4 (Docker).
- **VM2 (pentaho-server):** Pentaho Data Integration CE 9.4, where the transformations run.

## Data quality issues handled

| Issue | Example | Fix |
|---|---|---|
| Mixed date formats | `22.12.2025`, `2025/03/09` | Normalized to `YYYY-MM-DD` |
| Inconsistent text casing / Turkish characters | `ANKARA`, `Ankara`, `İZMİR` | Uppercased, Turkish characters mapped to ASCII |
| Quantity written as text | `iki` | Mapped to `2` |
| Negative quantity / price | `-3` | Converted to absolute value |
| Broken e-mail format | `name_at_example.net` | `_at_` replaced with `@` |
| Missing values | empty e-mail, city, payment method | Filled with default values |
| Duplicate orders | repeated `order_id` | Sorted and removed with Unique Rows |
| Inconsistent totals | `total_amount` ≠ quantity × price | Recalculated from cleaned fields |

## Star schema

One fact table (`fact_orders`) and four dimensions: `dim_customer`, `dim_product`, `dim_date`, `dim_payment`.
The schema is created by [`sql/01_create_star_schema.sql`](sql/01_create_star_schema.sql).

## Pentaho files

| File | Purpose |
|---|---|
| `pentaho/etl_load_dims.ktr` | Cleans the data and upserts the four dimension tables |
| `pentaho/etl_load_fact.ktr` | Cleans the data again, looks up dimension keys, writes `fact_orders` |
| `pentaho/etl_main_job.kjb` | Runs `Load_Dims` first, then `Load_Fact` |

### Race condition

In the first version everything ran in one transformation with parallel branches. The fact lookups started before the dimension tables were filled, and about 99.8% of the foreign keys came out as NULL. Splitting the flow into two transformations and running them in order inside a Job fixed it.

## How to run

1. Start a PostgreSQL 16 database and run `sql/01_create_star_schema.sql`.
2. Install Pentaho Data Integration CE 9.4 and open the three files in `pentaho/` with Spoon.
3. Edit the `PostgreSQL_DW` database connection (host, database, user, password) to match your setup.
4. In the CSV input step, change the file path to where `data/ecommerce_raw_data.csv` is on your machine.
5. Run `etl_main_job.kjb`.

## Validation results

After the load, validation queries confirmed:

| Table | Rows |
|---|---|
| fact_orders | 500 |
| dim_customer | 493 |
| dim_product | 20 |
| dim_date | 278 |
| dim_payment | 5 |

- 510 raw rows became 500 unique orders.
- No NULL foreign keys in `fact_orders`.
- No duplicate `order_id`.
- No negative quantities.
- Total amount: 6,426,383.43 TL across 500 orders (426 completed).


