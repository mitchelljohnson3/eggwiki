#
#
# Makefile for developing and building An Otter Wiki
#
# Please read the Installation guide <https://eggwiki.com/Installation>
# to get started.
#
#
PORT ?= 8080
VERSION := $(shell python3 -c "with open('eggwiki/version.py') as f: exec(f.read());  print(__version__);")
VERSION_MAJOR_MINOR := $(shell python3 -c "with open('eggwiki/version.py') as f: exec(f.read()); print('.'.join(__version__.split('.')[0:2]));")
VERSION_MAJOR := $(shell python3 -c "with open('eggwiki/version.py') as f: exec(f.read()); print('.'.join(__version__.split('.')[0:1]));")
PLATFORM ?= "linux/arm64,linux/amd64,linux/arm/v7,linux/arm/v6"

all: run

.PHONY: clean coverage run debug shell sdist docker-build docker-test

clean:
	rm -rf venv *.egg-info dist *.log* eggwiki/__pycache__ tests/__pycache__
	rm -rf .pytest_cache .tox
	rm -rf coverage_html

venv: pyproject.toml
	rm -rf venv
	python3 -m venv venv
	venv/bin/pip install -U pip wheel
	venv/bin/pip install -e '.[dev]'

run: venv settings.cfg
	GIT_TAG=$(shell git describe --long) FLASK_APP=eggwiki.server eggwiki_SETTINGS=$(PWD)/settings.cfg venv/bin/flask run --host 0.0.0.0 --port $(PORT)

debug: venv settings.cfg
	FLASK_ENV=development FLASK_DEBUG=True FLASK_APP=eggwiki.server eggwiki_SETTINGS=../settings.cfg venv/bin/flask run --port $(PORT)

profiler: venv settings.cfg
	FLASK_DEBUG=True FLASK_APP=eggwiki.server eggwiki_SETTINGS=../settings.cfg \
        venv/bin/python eggwiki/profiler.py


shell: venv
	FLASK_DEBUG=True FLASK_APP=eggwiki.server eggwiki_SETTINGS=../settings.cfg venv/bin/flask shell

test: venv
	eggwiki_SETTINGS="" venv/bin/pytest tests

tox: venv
	venv/bin/tox

venv/bin/coverage: venv
	venv/bin/pip install coverage

coverage: venv venv/bin/coverage
	eggwiki_SETTINGS="" venv/bin/coverage run --source=eggwiki -m pytest tests
	venv/bin/coverage report
	venv/bin/coverage html -d coverage_html

black:
	venv/bin/black setup.py eggwiki/ tests/

sdist: venv test
	venv/bin/python setup.py sdist

settings.cfg:
	@echo ""
	@echo " Please create the settings.cfg. You find an example in the"
	@echo " settings.cfg.skeleton"
	@echo ""
	@false

tmp/codemirror-5.65.15:
	mkdir -p tmp && \
	cd tmp && \
	test -f codemirror.zip || wget https://codemirror.net/5/codemirror.zip && \
	unzip codemirror.zip

eggwiki/static/js/cm-modes.min.js: tmp/codemirror-5.65.15
	cat tmp/codemirror-5.65.15/addon/mode/simple.js > eggwiki/static/js/cm-modes.js
	cat tmp/codemirror-5.65.15/mode/meta.js >> eggwiki/static/js/cm-modes.js
	for MODE in shell clike xml python javascript markdown yaml php sql \
		toml cmake perl http go rust dockerfile powershell properties \
		stex nginx; do \
		cat tmp/codemirror-5.65.15/mode/$$MODE/$$MODE.js \
			>> eggwiki/static/js/cm-modes.js; \
	done
	./venv/bin/python -m rjsmin -p < eggwiki/static/js/cm-modes.js > eggwiki/static/js/cm-modes.min.js

docker-test:
	# make sure the image is rebuild
	DOCKER_BUILDKIT=1 docker build --no-cache -t eggwiki:_test --target test-stage .

docker-run:
	DOCKER_BUILDKIT=1 docker build -t eggwiki:_build .
	docker run -p 8080:80 eggwiki:_build

docker-buildx-test:
ifeq ($(strip $(shell git rev-parse --abbrev-ref HEAD)),main)
	docker buildx build --no-cache --platform $(PLATFORM) --target test-stage .
else
	docker buildx build --no-cache --platform linux/arm64,linux/amd64 --target test-stage .
endif

docker-buildx-push: test
# check if we are in the main branch (to avoid accidently pushing a feature branch
ifeq ($(strip $(shell git rev-parse --abbrev-ref HEAD)),main)
# check if git is clean
ifneq ($(strip $(shell git status --porcelain)),)
	$(error Error: Uncommitted changes in found)
endif
	docker buildx build --platform $(PLATFORM) \
		-t redimp/eggwiki:latest \
		-t redimp/eggwiki:$(VERSION) \
		-t redimp/eggwiki:$(VERSION_MAJOR) \
		-t redimp/eggwiki:$(VERSION_MAJOR_MINOR) \
		--build-arg GIT_TAG="$(shell git describe --long)" \
		--push .
else
	@echo ""
	@echo "-- Building dev image"
	@echo ""
	docker buildx build --platform linux/arm64,linux/amd64 \
		-t redimp/eggwiki:dev-$(shell git rev-parse --abbrev-ref HEAD) \
		--build-arg GIT_TAG="$(shell git describe --long)_$(shell git rev-parse --abbrev-ref HEAD)" \
		--push .
	@echo ""
	@echo "-- Done dev-image: redimp/eggwiki:dev-$(shell git rev-parse --abbrev-ref HEAD)"
	@echo ""
endif

pypi: test
	./venv/bin/python3 -m pip install --upgrade build
	./venv/bin/python3 -m pip install --upgrade twine
	python3 -m build
	python3 -m twine upload dist/*
