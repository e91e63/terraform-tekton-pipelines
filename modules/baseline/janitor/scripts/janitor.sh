#!/bin/sh
set -eu
if [ "${DEBUG:=}" = true ]; then set -x; fi

echo "Starting $(basename "${0}")"
FAIL_TTL_MINUTES="${FAIL_TTL_MINUTES:?}"
NAMESPACE="${NAMESPACE:?}"
SUCCESS_KEEP_NUM="${SUCCESS_KEEP_NUM:?}"

PIPELINES=$(
    kubectl get "pipelinerun" \
        --namespace "${NAMESPACE}" \
        --output go-template \
        --template '{{range .items}}{{index .metadata.labels "tekton.dev/pipeline"}}{{"\n"}}{{end}}' |
        uniq
)

echo "$PIPELINES" | while read -r PIPELINE; do
    echo "pipeline: $PIPELINE"
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
    OLD=$(date -d@"$(($(date +%s) - FAIL_TTL_MINUTES * 60))" -Is --utc | sed 's/+0000/Z/')
    RUNS_FAILED_OLD=$(echo "${RUNS_FAILED}" | awk '$3 <= "'"${OLD}"'" {print $2}')
    echo "  deleting failed old runs:"
    echo "$RUNS_FAILED_OLD" | while read -r RUN; do
        test -n "${RUN}" || continue
        kubectl --namespace "${NAMESPACE}" delete "pipelinerun.tekton.dev/${RUN}" &&
            echo "    $(date -Is) PipelineRun ${RUN} deleted" ||
            echo "    $(date -Is) Unable to delete PipelineRun ${RUN}."
    done
    echo

    # Delete successful runs after certain number
    RUNS_SUCCESS=$(echo "${RUNS}" | { grep '^True' || true; })
    RUNS_SUCCESS_EXCESS=$(echo "${RUNS_SUCCESS}" | head -n -"${SUCCESS_KEEP_NUM}" | awk '{print $2}')
    echo "  deleting successful excess runs:"
    echo "$RUNS_SUCCESS_EXCESS" | while read -r RUN; do
        test -n "${RUN}" || continue
        kubectl delete "pipelinerun.tekton.dev/${RUN}" &&
            echo "    $(date -Is) PipelineRun ${RUN} deleted." ||
            echo "    $(date -Is) Unable to delete PipelineRun ${RUN}."
    done
    echo
done

echo "Finished $(basename "${0}")"
