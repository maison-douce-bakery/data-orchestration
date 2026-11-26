# data-orchestration

DAGs (`dags/`) and the runtime image for the data platform: the upstream Dagu image plus `git` and dbt.

- Dagu Git Sync pulls `dags/` from `main` into the running Dagu (pull only, push disabled).
- The dbt project is not here: each DAG run clones [data-transform](https://github.com/maison-douce-bakery/data-transform) and runs dbt there. The connection comes from `DBT_HOST`, `DBT_PORT`, `DBT_USER`, `DBT_PASSWORD` and `DBT_DBNAME`, set by the task definition.
- CI builds the image on every PR and pushes it to ECR `mdb/dagu-dbt` from `main`.
