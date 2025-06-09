FROM python:alpine

LABEL maintainer="admorelliribeiro@gmail.com" \
      org.opencontainers.image.source="https://github.com/admorelli/sirehp" \
      org.opencontainers.image.url="https://hub.docker.com/repository/docker/allfa/sirehp"

RUN apk add openrc git

COPY scripts/sync /usr/bin/sync
COPY scripts/kerko /usr/bin/kerko
COPY scripts/start /usr/bin/start

COPY scripts/crontabs-root /etc/crontabs/root

RUN chmod +x /usr/bin/sync
RUN chmod +x /usr/bin/kerko
RUN chmod +x /usr/bin/start

WORKDIR /kerkoapp
COPY ./kerkoapp /kerkoapp/kerkoapp
COPY ./requirements /kerkoapp/requirements
COPY ./babel.cfg /kerkoapp
COPY ./CHANGELOG.md /kerkoapp
COPY ./LICENSE.txt /kerkoapp
COPY ./pyproject.toml /kerkoapp
COPY ./wsgi.py /kerkoapp

RUN pip install --no-cache-dir --trusted-host pypi.python.org -r /kerkoapp/requirements/docker.txt
RUN for LOCALE in $(find kerkoapp/translations/* -maxdepth 0 -type d -exec basename "{}" \;); do \
      pybabel compile -l $LOCALE -d kerkoapp/translations; \
    done

ENTRYPOINT ["/usr/bin/start"]
CMD ["kerko"]
