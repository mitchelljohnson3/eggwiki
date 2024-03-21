export EGGWIKI_SETTINGS=$PWD/settings.cfg || bash;
./venv/bin/uwsgi --http 0.0.0.0:8080 --master --enable-threads --die-on-term -w eggwiki.server:app
