mkdir -p app-data/repository;
git init app-data/repository;
echo "REPOSITORY='${PWD}/app-data/repository'" >> settings.cfg;
echo "SQLALCHEMY_DATABASE_URI='sqlite:///${PWD}/app-data/db.sqlite'" >> settings.cfg;
echo "SECRET_KEY='$(echo $RANDOM | md5sum | head -c 16)'" >> settings.cfg;
python3 -m venv venv;
./venv/bin/pip install -U pip uwsgi;
./venv/bin/pip install .;
./start.sh