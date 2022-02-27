#!/usr/bin/env bash

sudo apt install software-properties-common
sudo add-apt-repository ppa:ondrej/php

sudo apt update
sudo apt install php8.0 php8.0-mbstring php8.0-dom