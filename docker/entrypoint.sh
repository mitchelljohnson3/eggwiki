#!/usr/bin/env bash
# vim:set et ts=8 sts=4 sw=4 ai fenc=utf-8:

set -e

# take care of repository dictionary
if [ ! -d ${eggwiki_REPOSITORY} ]; then
    mkdir -p ${eggwiki_REPOSITORY}
fi

if [ ! -d ${eggwiki_REPOSITORY}/.git ]; then
    git init ${eggwiki_REPOSITORY}
fi

# take care of the eggwiki settings file
if [ ! -f ${eggwiki_SETTINGS} ]; then
    RANDOM_SECRET_KEY=$(echo $RANDOM | md5sum | head -c 16)
    echo "DEBUG = False" >> ${eggwiki_SETTINGS}
    echo "REPOSITORY = '/app-data/repository'" >> ${eggwiki_SETTINGS}
    echo "SECRET_KEY = '${RANDOM_SECRET_KEY}'" >> ${eggwiki_SETTINGS}
    echo "SQLALCHEMY_DATABASE_URI = 'sqlite:////app-data/db.sqlite'" >> ${eggwiki_SETTINGS}
fi

# handle environment variables
# branding
for EV in SITE_NAME SITE_LOGO SITE_DESCRIPTION SITE_ICON; do
    if [ ! -z "${!EV}" ]; then
        sed -i "/^${EV}.*/d" ${eggwiki_SETTINGS}
        echo "${EV} = '${!EV}'" >> ${eggwiki_SETTINGS}
    fi
done
# permissions
for EV in READ_ACCESS WRITE_ACCESS ATTACHMENT_ACCESS; do
    if [ ! -z "${!EV}" ]; then
        sed -i "/^${EV}.*/d" ${eggwiki_SETTINGS}
        echo "${EV} = '${!EV}'" >> ${eggwiki_SETTINGS}
    fi
done
for EV in LOG_LEVEL AUTO_APPROVAL EMAIL_NEEDS_CONFIRMATION RETAIN_PAGE_NAME_CASE GIT_WEB_SERVER DISABLE_REGISTRATION; do
    if [ ! -z "${!EV}" ]; then
        sed -i "/^${EV}.*/d" ${eggwiki_SETTINGS}
        echo "${EV} = ${!EV}" >> ${eggwiki_SETTINGS}
    fi
done
# mail
for EV in MAIL_SERVER MAIL_USERNAME MAIL_PASSWORD MAIL_DEFAULT_SENDER; do
    if [ ! -z "${!EV}" ]; then
        sed -i "/^${EV}.*/d" ${eggwiki_SETTINGS}
        echo "${EV} = '${!EV}'" >> ${eggwiki_SETTINGS}
    fi
done
for EV in MAIL_PORT MAIL_USE_TLS MAIL_USE_SSL; do
    if [ ! -z "${!EV}" ]; then
        sed -i "/^${EV}.*/d" ${eggwiki_SETTINGS}
        echo "${EV} = ${!EV}" >> ${eggwiki_SETTINGS}
    fi
done

chown -R www-data:www-data /app-data

# Get the maximum upload file size for Nginx, default to 0: unlimited
USE_NGINX_MAX_UPLOAD=${NGINX_MAX_UPLOAD:-0}
# Get the number of workers for Nginx, default to 1
USE_NGINX_WORKER_PROCESSES=${NGINX_WORKER_PROCESSES:-1}
# Modify the number of worker processes in Nginx config
sed -i "/worker_processes\s/c\worker_processes ${USE_NGINX_WORKER_PROCESSES};" /etc/nginx/nginx.conf

# Get the URL for static files from the environment variable
USE_STATIC_URL=${STATIC_URL:-'/static'}
# Get the absolute path of the static files from the environment variable
USE_STATIC_PATH=${STATIC_PATH:-'/app/eggwiki/static'}
# Get the listen port for Nginx, default to 80
USE_LISTEN_PORT=${LISTEN_PORT:-80}

# Generate Nginx config first part using the environment variables
echo "server {
    listen ${USE_LISTEN_PORT};
    client_max_body_size $USE_NGINX_MAX_UPLOAD;
" > /etc/nginx/conf.d/default.conf

if [ ! -z "${REAL_IP_FROM}" ]; then
echo "    set_real_ip_from $REAL_IP_FROM;
    real_ip_header X-Real-IP;
    real_ip_recursive on;" >> /etc/nginx/conf.d/nginx.conf
fi


echo "    location / {
        try_files \$uri @app;
    }
    location @app {
        include uwsgi_params;
        uwsgi_pass unix:///tmp/uwsgi.sock;
    }
    location $USE_STATIC_URL {
        alias $USE_STATIC_PATH;
    }" >> /etc/nginx/conf.d/default.conf

# close the server block
echo "}" >> /etc/nginx/conf.d/default.conf

exec "$@"
