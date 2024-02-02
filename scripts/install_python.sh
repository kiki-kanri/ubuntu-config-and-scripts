#!/bin/bash

# Install python 3.12

sudo add-apt-repository ppa:deadsnakes/ppa -y &&
	sudo apt-get update &&
	sudo apt-get install -qy python3.12 libpython3.12-dev &&
	cd /tmp &&
	curl -sSL https://bootstrap.pypa.io/get-pip.py -o get-pip.py &&
	python3.12 get-pip.py &&
	rm -rf get-pip.py &&
	sudo apt-get reinstall -qy python3-pip &&
	sudo python3.12 -m pip install --upgrade --no-cache-dir pip setuptools wheel &&
	sudo python3.12 -m pip cache purge &&
	sudo python3 -m pip install --upgrade --no-cache-dir pip setuptools wheel &&
	sudo python3 -m pip cache purge
