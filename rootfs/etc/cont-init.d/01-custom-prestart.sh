#!/usr/bin/with-contenv bash
# shellcheck shell=bash

# Run custom pre-start script
PRESTART_SCRIPT="/local/pre-start.sh"

# check for Nomad template rendered script
if [ -f "$PRESTART_SCRIPT" ]; then
    echo "INFO: Executing $PRESTART_SCRIPT"
    chmod +x "$PRESTART_SCRIPT"
    "$PRESTART_SCRIPT" || true
fi

# check for PRESTART environment variable
if [ -n "${PRESTART}" ]; then
    echo "INFO: Executing pre-start script from assigned PRESTART variable"
    eval "${PRESTART}" || true
fi

exit 0
