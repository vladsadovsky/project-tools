#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

cd "$SCRIPT_DIR"

if ! command -v jq &> /dev/null; then
  sudo apt install -y jq
fi

if ! command -v curl &> /dev/null; then
  sudo apt install -y curl
fi

declare -a env_vars=(HUBITAT_HOST HUBITAT_ACCESS_TOKEN MQTT_HOST MQTT_PORT MQTT_USER MQTT_PASSWORD)

if [ -z "$MQTT_PORT" ]; then
  export MQTT_PORT=1883
fi

if [ -z "$MQTT_HOST" ]; then
  export MQTT_HOST='devfleet.mckelvie.org'
fi

if [ -z "${MQTT_USER+x}" ]; then
  export MQTT_USER='iotbox'
fi

if [ -z "${MQTT_PASSWORD+x}" ]; then
  echo "You must explicitly set MQTT_PASSWORD. If you will not be using MQTT or if your MQTT" >&2
  echo "serer does not require a password, you may set it to an empty string." >&2
  exit 1
fi

if [ -z "$HUBITAT_HOST" ] || [ -z "$HUBITAT_ACCESS_TOKEN" ]; then
  echo "HUBITAT_HOST or HUBITAT_ACCESS_TOKEN has not been set. You will not be able to talk to Hubitat." >&2
fi
rm -f ".dev-env"
touch ".dev-env"
for env_var in "${env_vars[@]}"; do
  if [ -n "${!env_var}" ]; then
    echo "$env_var=${!env_var}" >> ".dev-env"
  fi
done

if ! ( pip3 list | grep -G '^virtualenv ' > /dev/null ) ; then
  pip3 install --user virtualenv
fi

PYENV_DIR="$SCRIPT_DIR/venv"
if [ ! -d "$PYENV_DIR" ]; then
  python3 -m venv "$PYENV_DIR"
fi

ACTIVATE="$PYENV_DIR/bin/activate"
PYTHON="$PYENV_DIR/bin/python"
PIP3="$PYENV_DIR/bin/pip3"

if [ ! -e "$ACTIVATE" ]; then
  if [ -e "$ACTIVATE-orig" ]; then
    mv "$ACTIVATE-orig" "$ACTIVATE"
  else
    echo "venv activate script does not exist at $ACTIVATE" >&2
    exit 1
  fi
fi

if [[ ! -L "$ACTIVATE" ]]; then
  echo "hooking virtualenv activate script..." >&2
  mv "$ACTIVATE" "$ACTIVATE-orig"
  ln -s "../../env-vars.sh" "$ACTIVATE"
else
  echo "virtualenv activate script $ACTIVATE is already a symlink"
fi

if ! ( "$PIP3" list | grep -G '^wheel ' > /dev/null ) ; then
  "$PIP3" install wheel
fi

if ! ( "$PIP3" list | grep -G '^yq ' > /dev/null ) ; then
  "$PIP3" install yq
fi

"$PIP3" install -r requirements.txt

. "$SCRIPT_DIR/env-vars.sh"

"$PIP3" install --upgrade -e .

echo "Python is at $PYTHON"
echo "Python version is $($PYTHON --version)"
