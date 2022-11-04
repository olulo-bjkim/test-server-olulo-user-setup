#!/bin/bash

EB_ENV_NAME=$(/opt/elasticbeanstalk/bin/get-config container -k environment_name)
if [ -z "$EB_ENV_NAME" ]; then
    >&2 echo "eb environment name not found";
    exit 1;
fi

source /etc/environment

if [ -z "$OLULO_USER_SETUP_GITHUB_URL" ]; then
    echo "OLULO_USER_SETUP_GITHUB_URL is not defined"
    exit;
fi

download() {
    SRC=$1
    DST=$2

    USER=olulo
    PASSWD=$OLULO_USER_SETUP_GITHUB_TOKEN
    URL=$OLULO_USER_SETUP_GITHUB_URL/$EB_ENV_NAME/$SRC
    HTTP_STATUS=$(curl -I -w "%{http_code}" -o /dev/null -s -u "$USER:$PASSWD" "$URL")
    if [ $HTTP_STATUS == 200 ]; then
        echo "- download $SRC to $DST"
        curl -s -u "$USER:$PASSWD" "$URL" > "$DST"
    else
        echo "- http status for $SRC: $HTTP_STATUS"
    fi
}

SUDOERS=10-olulo
OLULO_SUDOERS=/etc/sudoers.d/$SUDOERS

download "sudoers.d/$SUDOERS" "$OLULO_SUDOERS"
if [ -f $OLULO_SUDOERS ]; then
    chmod 440 $OLULO_SUDOERS
fi

SSH_KEYS=authorized_keys
OLULO_SSH_DIR=/home/olulo/.ssh
OLULO_SSH_KEYS=$OLULO_SSH_DIR/$SSH_KEYS
if [ ! -d $OLULO_SSH_DIR ]; then
    mkdir $OLULO_SSH_DIR
fi
download "ssh/$SSH_KEYS" "$OLULO_SSH_KEYS"
if [ -f $OLULO_SSH_KEYS ]; then
    chown olulo.olulo $OLULO_SSH_KEYS
    chmod 400 $OLULO_SSH_KEYS
fi

