# data-orchestration

DAGs (`dags/`) and the runtime image for the data platform: the upstream Dagu image plus `git`, dbt (`/opt/dbt`, on `PATH`) and the dlt loader venv (`/opt/dlt`, called as `/opt/dlt/bin/python`).

- Dagu Git Sync pulls `dags/` from `main` into the running Dagu (pull only, push disabled).
- The dbt project is not here: each DAG run clones [data-transform](https://github.com/maison-douce-bakery/data-transform) and runs dbt there. The connection comes from `DBT_HOST`, `DBT_PORT`, `DBT_USER`, `DBT_PASSWORD` and `DBT_DBNAME`, set by the task definition.
- `weather_daily` (05:00 Ho Chi Minh City): invokes the Open-Meteo extract Lambda for the last 7 days, then loads the new files from S3 into Postgres with dlt, using [data-ingestion](https://github.com/maison-douce-bakery/data-ingestion).
- `weather_backfill` (manual): the same for a `START_DATE` to `END_DATE` range, up to about 3 months per run.
- The weather DAGs need `DATALAKE_BUCKET` and `DP_LOADER_*` in the task environment, and AWS credentials from the task role (the Dagu environment whitelist must allow the `AWS_` prefix).
- CI builds the image on every PR and pushes it to ECR `mdb/dagu-dbt` from `main`.
