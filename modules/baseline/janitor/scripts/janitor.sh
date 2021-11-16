#!/bin/sh
set -eu
if [ "${DEBUG:=}" = true ]; then set -x; fi

echo "Starting $(basename "${0}")"
FAIL_TTL_MINUTES="${FAIL_TTL_MINUTES:?}"
NAMESPACE="${NAMESPACE:?}"
SUCCESS_TTL_MINUTES="${SUCCESS_TTL_MINUTES:?}"
SUCCESS_KEEP_NUM="${SUCCESS_KEEP_NUM:?}"

PIPELINES=$(
    kubectl get "pipelinerun" \
        --namespace "${NAMESPACE}" \
        --output go-template \
        --template '{{range .items}}{{index .metadata.labels "tekton.dev/pipeline"}}{{"\n"}}{{end}}' |
        uniq
)

delete_runs() {
    RUNS="${1}"
    echo "$RUNS" | while read -r RUN; do
        test -n "${RUN}" || continue
        kubectl --namespace "${NAMESPACE}" delete "pipelinerun.tekton.dev/${RUN}" ||
            echo "$(date -Is) unable to delete pipelinerun ${RUN}."
    done
}

filter_old() {
    RUNS="${1}"
    MINUTES=${2}

    OLD=$(date -d@"$(($(date +%s) - MINUTES * 60))" -Is --utc | sed 's/+0000/Z/')
    echo "${RUNS}" | awk '$3 <= "'"${OLD}"'" {print $2}'
}

echo "$PIPELINES" | while read -r PIPELINE; do
    RUNS=$(
        kubectl get "pipelinerun" \
            --namespace "${NAMESPACE}" \
            --output go-template \
            --selector "tekton.dev/pipeline=${PIPELINE}" \
            --sort-by ".metadata.creationTimestamp" \
            --template '{{range .items}}{{(index .status.conditions 0).status}} {{.metadata.name}} {{.metadata.creationTimestamp}}{{"\n"}}{{end}}'
    )

    # status values:
    # True is success
    # False is failed
    # Unknown is running

    # Delete old failed runs to release persistent volume claims
    RUNS_FAILED=$(echo "${RUNS}" | { grep '^False' || true; })
    RUNS_DELETE="$(filter_old "${RUNS_FAILED}" "${FAIL_TTL_MINUTES}")"

    # Delete old successful runs to release persistent volume claims
    RUNS_SUCCESS=$(echo "${RUNS}" | { grep '^True' || true; })
    RUNS_DELETE="${RUNS_DELETE}$(filter_old "${RUNS_SUCCESS}" "${SUCCESS_TTL_MINUTES}")"

    # Delete successful runs after certain number
    RUNS_DELETE="${RUNS_DELETE}$(echo "${RUNS_SUCCESS}" | head -n -"${SUCCESS_KEEP_NUM}" | awk '{print $2}' | awk END'{print "\n"}')"

    RUNS_DELETE=$(echo "${RUNS_DELETE}" | sort | uniq)
    delete_runs "${RUNS_DELETE}"
done

echo "Finished $(basename "${0}")"
