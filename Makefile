.PHONY: setup build

VENV := venv
PIP := $(VENV)/bin/pip
GLYPHS := sources/VerticalMetricsTest.glyphspackage
OUTPUTDIR := fonts

setup:
	python3 -m venv $(VENV)
	$(PIP) install --upgrade pip
	$(PIP) install -r requirements.txt

build:
	rm -rf $(OUTPUTDIR)
	$(VENV)/bin/fontmake -o ttf -i -g '$(GLYPHS)' --output-dir $(OUTPUTDIR)

install:
	rm -rf ~/Library/Fonts/00-vertical-metrics-tests
	cp -r fonts ~/Library/Fonts/00-vertical-metrics-tests