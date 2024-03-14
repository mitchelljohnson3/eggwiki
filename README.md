![](screenshot.png)

# An Egg Wiki

An Egg Wiki is a simple fork of An Otter Wiki.

An Egg Wiki is Python-based software for collaborative content
management, called a [wiki](https://en.wikipedia.org/wiki/Wiki). The
content is stored in a git repository, which keeps track of all changes.
[Markdown](https://daringfireball.net/projects/markdown) is used as
Markup language. An Otter Wiki is written in [python](https://www.python.org/)
using the microframework [Flask](http://flask.pocoo.org/).
[halfmoon](https://www.gethalfmoon.com) is used as CSS framework
and [CodeMirror](https://codemirror.net/) as editor.
[Font Awesome Free](https://fontawesome.com/license/free) serves the icons.

## Notable Features

- Minimalistic interface (with dark-mode)
- Editor with markdown highlighting and support including tables
- Full changelog and page history
- User authentication
- Page Attachments
- A very cute Egg as logo (drawn by [Alex Blaskovich](https://ablask3.wixsite.com/my-site) CC BY 3.0).

## Local Installation w/ uwsgi
1. clone repository
- git clone https://github.com/redimp/otterwiki.git

2. cd into repository
- cd otterwiki

3. create settings file
- echo "REPOSITORY='${PWD}/app-data/repository'" >> settings.cfg
- echo "SQLALCHEMY_DATABASE_URI='sqlite:///${PWD}/app-data/db.sqlite'" >> settings.cfg
- echo "SECRET_KEY='$(echo $RANDOM | md5sum | head -c 16)'" >> settings.cfg

4. create virtual environment
- python3 -m venv venv

5. install otterwiki
- ./venv/bin/pip install -U pip uwsgi
- ./venv/bin/pip install .

6. export settings file
- export OTTERWIKI_SETTINGS=$PWD/settings.cfg

7. run otterwiki
- ./venv/bin/uwsgi --http 127.0.0.1:8080 --master --enable-threads --die-on-term -w otterwiki.server:app

8. create a systemd service file
```
[Unit]
Description=uWSGI server for An Egg Wiki

[Service]
User=root
Group=root
WorkingDirectory=/path/to/an/eggwiki
ExecStart=/path/to/an/eggwiki/env/bin/uwsgi --http 127.0.0.1:8080 --enable-threads --die-on-term -w otterwiki.server:app
SyslogIdentifier=otterwiki
Environment="OTTERWIKI_SETTINGS=/path/to/an/eggwiki/settings.cfg"

[Install]
WantedBy=multi-user.target
```


## Installation / Configuration Guides

Read the [installation guide](https://otterwiki.com/Installation) to get
started. Recommended is the installation with `docker-compose`.

Proceed for the [configuration guide](https://otterwiki.com/Configuration) for
detailed information.

## License

An Egg Wiki is open-source software licensed under the [MIT License](https://github.com/redimp/otterwiki/blob/main/LICENSE).

[modeline]: # ( vim: set fenc=utf-8 spell spl=en sts=4 et tw=72: )
