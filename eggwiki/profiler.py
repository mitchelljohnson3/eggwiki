#!/env/bin/python
"""
This script can be used to profile flask using the werkzeug middleware
for cProfile.

FLASK_DEBUG=True FLASK_APP=eggwiki.server eggwiki_SETTINGS=../settings.cfg \
        venv/bin/python eggwiki/profiler.py

Handle with curl to not get overwhelmed.
"""

from werkzeug.middleware.profiler import ProfilerMiddleware
import cProfile
from eggwiki.server import app

app.config['PROFILE'] = True
app.wsgi_app = ProfilerMiddleware(app.wsgi_app, restrictions=[30])

with cProfile.Profile() as pr:
    app.run(debug = True, port=8080)
