./venv/bin/uwsgi --http 127.0.0.1:8080 --master --enable-threads --die-on-term -w otterwiki.server:app
