FROM python:3.9-slim as base

FROM base as builder
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install dumb-init -y \
    && apt-get clean \
    && apt-get autoclean \
    && python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
COPY requirements.txt /requirements.txt
RUN pip install --upgrade pip \
    && pip install -r /requirements.txt

FROM base
# Make sure we use the virtualenv:
ENV PATH="/opt/venv/bin:$PATH"
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install dumb-init -y \
    && apt-get clean \
    && apt-get autoclean
COPY --from=builder /opt/venv /opt/venv
COPY . /app
WORKDIR /app
EXPOSE 8000
USER nobody
CMD ["dumb-init", "gunicorn", "--bind", "0.0.0.0:8000", "-w 4", "app:app"]