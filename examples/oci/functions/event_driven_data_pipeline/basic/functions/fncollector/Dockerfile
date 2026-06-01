FROM oraclelinux:9-slim as ol9

RUN microdnf install -y wget \
    tar \
    gzip \
    which

FROM fnproject/python:3.11-dev as build-stage

WORKDIR /function

ADD requirements.txt /function/

RUN pip3 install --target /python/ --no-cache --no-cache-dir -r requirements.txt && \
    rm -fr ~/.cache/pip /tmp* requirements.txt func.yaml Dockerfile .venv

ADD . /function/

RUN rm -fr /function/.pip_cache

FROM fnproject/python:3.11

WORKDIR /function

COPY --from=build-stage /function /function
COPY --from=build-stage /python /python

ENV PYTHONPATH=/python
ENV TNS_ADMIN=/tmp/adb_wallet

ENTRYPOINT ["/python/bin/fdk", "/function/func.py", "handler"]
