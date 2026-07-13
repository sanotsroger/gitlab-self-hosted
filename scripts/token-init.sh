#!/bin/bash
set -e

if [ -f /token/runner-token.txt ]; then
  echo "Token já existe, pulando criação."
  exit 0
fi

echo "Aguardando gitlab-rails ficar disponível..."
until [ "$(docker exec gitlab-server gitlab-rails runner 'puts "ok"' 2>/dev/null)" = "ok" ]; do
  sleep 5
done

echo "Gerando Personal Access Token do root via script Ruby..."
docker exec gitlab-server gitlab-rails runner /scripts/create_pat.rb > /tmp/rails_output.txt 2>&1 || true

echo "----- Saída completa do gitlab-rails runner -----"
cat /tmp/rails_output.txt
echo "---------------------------------------------------"

PAT=$(awk '/PAT_MARKER_START/{flag=1; next} /PAT_MARKER_END/{flag=0} flag' /tmp/rails_output.txt | tr -d '[:space:]')

if echo "$PAT" | grep -qE '^glpat-[A-Za-z0-9_.-]+$'; then
  echo "PAT válido encontrado e extraído com sucesso."
else
  echo "Falha: não foi encontrado um PAT com formato válido na saída acima."
  if grep -q 'PAT_ERROR_START' /tmp/rails_output.txt; then
    echo "Erro reportado pelo Rails:"
    sed -n '/PAT_ERROR_START/,/PAT_ERROR_END/p' /tmp/rails_output.txt
  fi
  exit 1
fi

echo "Testando conectividade e autenticação com ${GITLAB_INTERNAL_URL}..."
HTTP_STATUS=$(curl -s -o /tmp/curl_test_body.txt -w "%{http_code}" -m 10 \
  --header "PRIVATE-TOKEN: ${PAT}" \
  "${GITLAB_INTERNAL_URL}/api/v4/version")

if [ "$HTTP_STATUS" != "200" ]; then
  echo "Falha na conectividade/autenticação (HTTP $HTTP_STATUS)."
  echo "Resposta:"
  cat /tmp/curl_test_body.txt
  exit 1
fi
echo "Conectividade e autenticação OK (HTTP $HTTP_STATUS)."

echo "Criando runner via API REST..."
RESPONSE=$(curl -s -f -m 20 --request POST "${GITLAB_INTERNAL_URL}/api/v4/user/runners" \
  --header "PRIVATE-TOKEN: ${PAT}" \
  --form "runner_type=instance_type" \
  --form "description=${GITLAB_RUNNER_DESCRIPTION:-docker-runner}" \
  --form "tag_list=${GITLAB_RUNNER_TAGS:-docker}" \
  --form "run_untagged=true") || {
    echo "curl falhou (timeout, conexão recusada, ou HTTP != 2xx)."
    exit 1
  }

TOKEN=$(echo "$RESPONSE" | jq -r '.token // empty')

if [ -z "$TOKEN" ]; then
  echo "Falha ao obter token do runner. Resposta da API:"
  echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
  exit 1
fi

echo "$TOKEN" > /token/runner-token.txt
echo "Token do runner salvo com sucesso."

echo "Revogando PAT temporário do root..."
docker exec gitlab-server gitlab-rails runner /scripts/revoke_pat.rb || echo "Aviso: não foi possível revogar o PAT."