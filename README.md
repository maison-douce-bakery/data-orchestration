# data-orchestration

DAGs (`dags/`) and the runtime image for the data platform: the upstream Dagu image plus `git`, dbt (`/opt/dbt`, on `PATH`) and the dlt loader venv (`/opt/dlt`, called as `/opt/dlt/bin/python`).

- Dagu Git Sync pulls `dags/` from `main` into the running Dagu (pull only, push disabled).
- The dbt project is not here: each DAG run clones [data-transform](https://github.com/maison-douce-bakery/data-transform) and runs dbt there. The connection comes from `DBT_HOST`, `DBT_PORT`, `DBT_USER`, `DBT_PASSWORD` and `DBT_DBNAME`, set by the task definition.
- `daily_pipeline` (05:00 Ho Chi Minh City): runs `weather_ingest`, then `dbt_build`. Run it by hand with a larger `LOOKBACK_DAYS` (up to about 90) to backfill weather.
- `weather_ingest` (manual or called by `daily_pipeline`): invokes the Open-Meteo extract Lambda for the last `LOOKBACK_DAYS` days (default 7), then loads the new files from S3 into Postgres with dlt, using [data-ingestion](https://github.com/maison-douce-bakery/data-ingestion).
- `dbt_build` (manual or called by `daily_pipeline`): builds the whole warehouse; pass `DBT_ARGS` to run a subset, for example `--select stg_open_meteo__hourly_weather+ branch_locations`.
- `_marmot_postgres_pipeline` (manual only): clones [data-catalog](https://github.com/maison-douce-bakery/data-catalog) at `CATALOG_REF` (default `main`) and registers or updates the Marmot PostgreSQL pipeline `bakery-postgres` (and sets the admin password on a fresh Marmot); it does not run it. Needs the `MARMOT_*` variables in the task environment.
- `_marmot_enrich` (manual only): clones [data-catalog](https://github.com/maison-douce-bakery/data-catalog) at `CATALOG_REF` and [commerce-api](https://github.com/maison-douce-bakery/commerce-api) at `APP_REF` (both default `main`) and enriches the synced Marmot catalog with business metadata from the commerce-api DDL; pass `ENRICH_ARGS=--dry-run` to show the changes without writing. Needs the `MARMOT_*` variables in the task environment.
- The weather DAGs need `DATALAKE_BUCKET` and `DP_LOADER_*` in the task environment, and AWS credentials from the task role (the Dagu environment whitelist must allow the `AWS_` prefix).
- CI builds the image on every PR and pushes it to ECR `mdb/dagu-dbt` from `main`.
