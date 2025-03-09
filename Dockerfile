FROM python:alpine

LABEL maintainer="admorelliribeiro@gmail.com" \
      org.opencontainers.image.source="https://github.com/admorelli/sirehp" \
      org.opencontainers.image.url="https://hub.docker.com/repository/docker/allfa/sirehp"

WORKDIR /kerkoapp
COPY . /kerkoapp

RUN apk add --no-cache git apk-cron
RUN echo "0 0 * * * /usr/bin/sync" > /etc/crontabs/root
RUN printf "#!/bin/sh\nflask kerko sync" > /usr/bin/sync
RUN chmod +x /usr/bin/sync
RUN pip install --no-cache-dir --trusted-host pypi.python.org -r /kerkoapp/requirements/docker.txt
RUN for LOCALE in $(find kerkoapp/translations/* -maxdepth 0 -type d -exec basename "{}" \;); do pybabel compile -l $LOCALE -d kerkoapp/translations; done

CMD ["crond", "-l 2", "-f", "&&", "gunicorn", "--threads", "4", "--log-level", "info", "--error-logfile", "-", "--access-logfile", "-", "--worker-tmp-dir", "/dev/shm", "--graceful-timeout", "120", "--timeout", "120", "--keep-alive", "5", "--bind", "0.0.0.0:80", "wsgi:app"]
