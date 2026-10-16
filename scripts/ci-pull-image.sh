#!/bin/bash
# ci-pull-image.sh: pull a Docker official image from the first registry that serves it and tag it under its Docker Hub name.
# Usage: ci-pull-image.sh IMAGE:TAG [PLATFORM]
set -uo pipefail
image=$1
platform_args=()
if [ -n "${2:-}" ]; then
    platform_args=(--platform "$2")
fi
for prefix in "" mirror.gcr.io/library/ public.ecr.aws/docker/library/; do
    for attempt in 1 2; do
        if docker pull "${platform_args[@]}" "$prefix$image"; then
            if [ -n "$prefix" ]; then
                docker tag "$prefix$image" "$image"
            fi
            exit 0
        fi
        sleep $((attempt * 5))
    done
done
echo "ci-pull-image: no registry served $image" >&2
exit 1
