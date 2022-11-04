#!/bin/bash

source /etc/environment

if [ -z "$OLULO_USER_SETUP_GITHUB_URL" ] then
    echo "OLULO_USER_SETUP_GITHUB_URL is not defined"
    exit;
fi

