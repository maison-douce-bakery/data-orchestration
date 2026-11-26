FROM ghcr.io/astral-sh/uv:0.13.10@sha256:a3ea1357342c1a4bf9a0c53a3deb1b55379aefa037338d8113d5771efa01774f AS uv

FROM ghcr.io/dagucloud/dagu:2.27.0-alpine@sha256:bfe39d9ee261fcb69992308ef0419229e31ced8474032a9f507181b3edc86787

# The image holds only tools: DAGs come from Git Sync and the dbt project is cloned at run time.
# dbt does not support the base image's Python 3.14, so uv installs a pinned Python 3.12 for it.
# Installs run as root; the base entrypoint drops to the dagu user at start.
RUN apk add --no-cache git
COPY --from=uv /uv /usr/local/bin/uv
COPY requirements.txt /tmp/requirements.txt
RUN UV_PYTHON_INSTALL_DIR=/opt/python uv venv --python 3.12.16 --no-config /opt/dbt \
    && uv pip install --python /opt/dbt/bin/python --no-cache -r /tmp/requirements.txt \
    && rm /tmp/requirements.txt /usr/local/bin/uv \
    && ln -s /opt/dbt/bin/dbt /usr/local/bin/dbt

ENV PATH="/opt/dbt/bin:${PATH}" \
    DBT_TARGET_PATH=/tmp/dbt/target \
    DBT_LOG_PATH=/tmp/dbt/logs \
    DBT_SEND_ANONYMOUS_USAGE_STATS=false
