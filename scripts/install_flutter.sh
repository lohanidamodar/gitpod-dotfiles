#!/usr/bin/env bash

wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_2.10.3-stable.tar.xz

tar xf flutter_linux_2.10.3-stable.tar.xz

export PATH="$PATH:`pwd`/flutter/bin"
