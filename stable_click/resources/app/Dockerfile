FROM tiangolo/uwsgi-nginx-flask:python3.7

COPY ./app /app

RUN chmod -R 707 $STATIC_PATH

RUN pip install -r /app/requirements.txt