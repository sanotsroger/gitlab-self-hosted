#!/bin/bash
set -e

if [ ! -f /etc/gitlab-runner/config.toml ]; then
  TOKEN=$(cat /token/runner-token.txt)

  if [ -z "$TOKEN" ]; then
    echo "Arquivo de token vazio ou não encontrado em /token/runner-token.txt"
    exit 1
  fi

  echo "Registrando runner..."
  gitlab-runner register \
    --non-interactive \
    --url "http://${GITLAB_IP}" \
    --token "${TOKEN}" \
    --executor "docker" \
    --name "${GITLAB_RUNNER_TAGS}" \
    --docker-image "${GITLAB_RUNNER_DOCKER_IMAGE}" \
    --docker-volumes "/var/run/docker.sock:/var/run/docker.sock"

  echo "Aplicando ajustes customizados no config.toml..."
  sed -i -E '
    s/^concurrent = 1$/concurrent = 4/
    /^check_interval = 0$/a connection_max_age = "15m0s"
    s/^([[:space:]]*)url = "http:\/\/'"${GITLAB_IP}"'"$/&\n\1clone_url = "http:\/\/'"${GITLAB_IP}"'"/
    s/^([[:space:]]*)executor = "docker"[[:space:]]*$/&\n\1request_concurrency = 2/
    s/^([[:space:]]*)network_mtu = 0$/&\n\1network_mode = "gitlab-network"/
  ' /etc/gitlab-runner/config.toml
else
  echo "Runner já registrado, pulando registro e ajustes."
fi

exec gitlab-runner run --user=gitlab-runner --working-directory=/home/gitlab-runner