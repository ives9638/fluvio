#!/usr/bin/env bash
set -e

readonly PROGDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Package fluvio-run into a Docker image
#
# PARAMS:
# $1: The tag to build this Docker image with
#       Ex: 0.7.4-abcdef (where abcdef is a git commit)
# $2: The path to the fluvio-run executable
#       Ex: target/x86_64-unknown-linux-musl/$CARGO_PROFILE/fluvio-run
# $3: Whether to build this Docker image in the Minikube context
#       Ex: true, yes, or anything else that is non-empty
main() {
  local -r target=$1; shift
  local -r commit_hash=$1; shift
  local -r fluvio_run=$1; shift
  local -r K8=$1
  local -r tmp_dir=$(mktemp -d -t fluvio-docker-image-XXXXXX)
  local -r docker_tag="infinyon/fluvio:${commit_hash}-$target"
  local build_args

  if [ "$K8" = "minikube" ]; then
    echo "Setting Minikube build context"
    eval $(minikube -p minikube docker-env)
  fi

  cp "${fluvio_run}" "${tmp_dir}/fluvio-run"
  chmod +x "${tmp_dir}/fluvio-run"
  cp "${PROGDIR}/fluvio.Dockerfile" "${tmp_dir}/Dockerfile"

  if [ "$target" = "aarch64-unknown-linux-musl" ]; then
    local build_args="--build-arg ARCH=arm64v8/"
  fi

  pushd "${tmp_dir}"
  docker build -t $docker_tag $build_args .

  if [ "$K8" = "k3d" ]; then
    echo "export image to k3d cluster"
    docker image save infinyon/fluvio:${docker_tag} --output /tmp/infinyon-fluvio.tar
    k3d image import -k /tmp/infinyon-fluvio.tar -c fluvio
  fi

  if [ "$K8" = "kind" ]; then
    echo "export image to kind cluster"
    kind load docker-image infinyon/fluvio:${docker_tag}
  fi    

  popd || true
  rm -rf "${tmp_dir}"
}

main "$@"
