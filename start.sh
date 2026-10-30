#!/bin/bash
# Startup wrapper for hosting with no persistent disk (Render free tier).
# The database is kept between restarts, but files are wiped, so this script
# restores the config, re-applies the demo customizations, then runs the
# official EspoCRM entrypoint. A background loop runs scheduled jobs.
set -euo pipefail

APP=/var/www/html
cd "$APP"

export ESPOCRM_SITE_URL="${ESPOCRM_SITE_URL:-${RENDER_EXTERNAL_URL:-http://localhost}}"

# Demo customizations (entities, fields, layouts, labels).
cp -a /usr/src/demo/custom/. "$APP/custom/"
cp -a /usr/src/demo/client-custom/. "$APP/client/custom/"

# After a restart the database still holds the installation: restore the
# config so EspoCRM upgrades in place instead of reinstalling.
if [ "$(bin/command config:get isInstalled 2>/dev/null || true)" != "true" ] && php /usr/local/bin/db-has-install.php; then
    echo >&2 "info: Existing installation found in the database. Restoring config."
    bin/command config:populate
    bin/command config:set defaultPermissions.user www-data
    bin/command config:set defaultPermissions.group www-data
    bin/command config:set database.platform "${ESPOCRM_DATABASE_PLATFORM:-Mysql}"
    bin/command config:set database.host "$ESPOCRM_DATABASE_HOST"
    bin/command config:set database.port "${ESPOCRM_DATABASE_PORT:-}"
    bin/command config:set database.dbname "$ESPOCRM_DATABASE_NAME"
    bin/command config:set database.user "$ESPOCRM_DATABASE_USER"
    bin/command config:set database.password "$ESPOCRM_DATABASE_PASSWORD"
    bin/command config:set siteUrl "$ESPOCRM_SITE_URL"
    bin/command config:set isInstalled true --type=bool
fi

# Background: once EspoCRM is ready, load the customizations into the schema,
# apply demo settings, then keep the job runner going.
(
    until bin/command app-check >/dev/null 2>&1; do sleep 5; done
    chown -R www-data:www-data data custom client/custom
    as_web() { runuser -u www-data -- "$@"; }
    as_web bin/command config:set currencyList '["EGP"]' --type=json
    as_web bin/command config:set defaultCurrency EGP
    as_web bin/command config:set baseCurrency EGP
    as_web bin/command rebuild >/dev/null 2>&1 || echo >&2 "warning: rebuild failed"
    as_web bin/command config:set siteUrl "$ESPOCRM_SITE_URL"
    as_web bin/command config:set tabList "$(cat /usr/src/demo/tab-list.json)" --type=json
    as_web bin/command config:set quickCreateList '["Lead","Contact","Unit","Reservation","Meeting","Call","Task"]' --type=json
    as_web bin/command clear-cache >/dev/null 2>&1 || true
    echo >&2 "info: Demo settings applied."
    while true; do
        as_web php "$APP/daemon.php" || true
        sleep 5
    done
) &

# Run the official entrypoint; if it fails, print EspoCRM's log so the cause
# shows up in the hosting platform's logs.
docker-entrypoint.sh "$@" || {
    status=$?
    echo >&2 "---- EspoCRM log (last 60 lines) ----"
    tail -n 60 data/logs/*.log >&2 2>/dev/null || echo >&2 "(no log file)"
    exit $status
}
