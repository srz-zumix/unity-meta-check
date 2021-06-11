#!/bin/bash

set -euxo pipefail

cd "${GITHUB_WORKSPACE}" || exit

COMMON_ARGS="${INPUT_DEBUG}" "${INPUT_SILENT}"

function junit() {
    cat -
}

function auto_fix() {
    if "${INPUT_AUTO_FIX}"; then
        AUTO_FIX_OPTS=
        if "${INPUT_DRY_RUN}"; then
            AUTO_FIX_OPTS=${AUTO_FIX_OPTS} -dry-run
        fi
        if "${INPUT_FIX_DANGLING}"; then
            AUTO_FIX_OPTS=${AUTO_FIX_OPTS} -fix-dangling
        fi
        if "${INPUT_FIX_MISSING}"; then
            AUTO_FIX_OPTS=${AUTO_FIX_OPTS} -fix-missing
        fi
        cat - | unity-meta-autofix ${AUTO_FIX_OPTS}
    else
        cat -
    fi
}

function pr_comment() {
    if [ "${GITHUB_EVENT_NAME}" = "pull_request" ]; then
        PR_COMMENT_OPTS=
        if [ -n "${INPUT_TEMPLATE_FILE}" ]; then
            PR_COMMENT_OPTS=${PR_COMMENT_OPTS} -template-file "${INPUT_TEMPLATE_FILE}"
        fi
        PR_NUMBER=$(echo $GITHUB_REF | awk 'BEGIN { FS = "/" } ; { print $3 }')

        cat - | unity-meta-check-github-pr-comment \
            -owner "${GITHUB_REPOSITORY%/*}" -repo "${GITHUB_REPOSITORY#*/}" \
            -pull "${PR_NUMBER}" \
            -api-endpoint "${GITHUB_API_URL}" \
            -lang "${INPUT_LANG}" \
            ${PR_COMMENT_OPTS}
    else
        cat -
    fi
}

META_CHECK_OPTS=
if "${INPUT_UNITY_PROJECT}"; then
    META_CHECK_OPTS=${META_CHECK_OPTS} -unity-project
fi
if "${INPUT_UNITY_PROJECT_SUB_DIR}"; then
    META_CHECK_OPTS=${META_CHECK_OPTS} -unity-project-sub-dir
fi
if [ -n "${INPUT_IGNORE_FILE}" ]; then
    META_CHECK_OPTS=${META_CHECK_OPTS} -ignore-file "${INPUT_IGNORE_FILE}"
fi
if "${INPUT_IGNORE_DANGLING}"; then
    META_CHECK_OPTS=${META_CHECK_OPTS} -ignore-dangling
fi
if "${INPUT_IGNORE_SUBMODULES}"; then
    META_CHECK_OPTS=${META_CHECK_OPTS} -ignore-submodules
fi
if "${INPUT_NO_IGNORE_CASE}"; then
    META_CHECK_OPTS=${META_CHECK_OPTS} -no-ignore-case
fi

unity-meta-check ${COMMON_ARGS} ${META_CHECK_OPTS} "${INPUT_PATH}" \
    | junit() \
    | auto_fix() \
    | pr_comment()
