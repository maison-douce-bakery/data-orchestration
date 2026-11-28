FROM ghcr.io/astral-sh/uv:0.13.10@sha256:a3ea1357342c1a4bf9a0c53a3deb1b55379aefa037338d8113d5771efa01774f AS uv

# openlineage-dbt needs openlineage-sql, which has no musl wheel on PyPI: build it here. Keep the pin equal to openlineage-dbt.
FROM rust:1-alpine@sha256:8d0e82abfdf9a38071e07cabc5afba4ddbe077631a80e4e742a760c38beadc33 AS sqlwheel
RUN apk add --no-cache python3 py3-pip build-base maturin \
    && pip wheel --no-deps -w /wheels openlineage-sql==1.55.0

FROM ghcr.io/dagucloud/dagu:2.27.0-alpine@sha256:bfe39d9ee261fcb69992308ef0419229e31ced8474032a9f507181b3edc86787

# The image holds only tools: DAGs come from Git Sync and the dbt project is cloned at run time.
# dbt does not support the base image's Python 3.14, so uv installs a pinned Python 3.12 for it.
# The weather pipeline gets its own venv (/opt/dlt, same Python); DAGs call /opt/dlt/bin/python directly.
# Installs run as root; the base entrypoint drops to the dagu user at start.
# openssl is upgraded to the patched Alpine build (ECR scan findings on 3.5.9-r0); drop it once the base image ships it.
RUN apk add --no-cache git libgcc && apk upgrade --no-cache libcrypto3 libssl3
COPY --from=uv /uv /usr/local/bin/uv
COPY requirements.txt requirements-load.txt /tmp/
COPY --from=sqlwheel /wheels /tmp/wheels
RUN UV_PYTHON_INSTALL_DIR=/opt/python uv venv --python 3.12.16 --no-config /opt/dbt \
    && uv pip install --python /opt/dbt/bin/python --no-cache --find-links /tmp/wheels -r /tmp/requirements.txt \
    && UV_PYTHON_INSTALL_DIR=/opt/python uv venv --python 3.12.16 --no-config /opt/dlt \
    && uv pip install --python /opt/dlt/bin/python --no-cache -r /tmp/requirements-load.txt \
    && rm -rf /tmp/wheels /tmp/requirements.txt /tmp/requirements-load.txt /usr/local/bin/uv \
    && ln -s /opt/dbt/bin/dbt /usr/local/bin/dbt

ENV PATH="/opt/dbt/bin:${PATH}" \
    DBT_TARGET_PATH=/tmp/dbt/target \
    DBT_LOG_PATH=/tmp/dbt/logs \
    DBT_SEND_ANONYMOUS_USAGE_STATS=false
