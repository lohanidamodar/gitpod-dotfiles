#!/usr/bin/env bash

sudo apt install -y software-properties-common
sudo add-apt-repository ppa:ondrej/php

sudo apt update
sudo apt install -y php php-mbstring php-curl php-xml
