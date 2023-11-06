#!/bin/bash

set -x

if [[ "${MAKECOVERAGE}" = "false" ]];then
    pip install click-odoo-contrib;
    oca_wait_for_postgres
    ADDONS=$(manifestoo --select-addons-dir ${ADDONS_DIR} list-depends --separator=,)
    if [ -n "${ADDONS}" ]; then
        ADDONS="$ADDONS,${1}"
    else
        ADDONS=="${1}"
    fi
    unbuffer coverage run --include "${ADDONS_DIR}/*" --branch \
        $(which odoo || which openerp-server) \
        -d ${PGDATABASE} \
        -i ${ADDONS:-base} \
        --max-cron-threads=0 \
        --stop-after-init;
fi

click-odoo-makepot \
    --modules ${1} \
    --addons-dir ${ADDONS_DIR} \
    -d ${PGDATABASE} \
    --msgmerge-if-new-pot \
    --log-level=info;

mv ./${1}/* ./ && rmdir ./${1}

git config --global --add safe.directory $(pwd)
git config user.name aurestic-ci
git config user.email aurestic-ci@aurestic.es

rm test-requirements.txt;
git status;
git add i18n/${1}.pot;
git commit -m "[UPD] Update ${1}.pot";
git remote set-url origin $2
git fetch origin

LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse @{u})
BASE=$(git merge-base @ @{u})

if [ $LOCAL = $REMOTE ]; then
    echo "[INFO] No local change to push."
elif [ $REMOTE = $BASE ]; then
    echo "[INFO] Pushing changes..."
    git push origin
else
    echo "[INFO] Remote has evolved since we cloned, not pushing."
fi
