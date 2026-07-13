# Gitlab Self Hosted

## Network

Cria rede para cominicação entre os containers.

```shell
docker network create --gateway 172.16.0.1 --subnet 172.16.0.0/24 gitlab-network
```

## Registry

Alguns comandos úteis para verificar se o `registry` esta sendo executado.

Dentro do container do `gitlab-server` digite o seguinte comando:

```shell
gitlab-ctl status registry
```

Se uma mensage semelhante aparecer então esta tydo ok

```shell
run: registry: (pid 3714) 56s; run: log: (pid 1878) 107s
```

Para testar o `Registry` e ver se esta tudo ok, vamos tentar uma conexão a partir de um terminal fora do container.

```shell
docker login localhost:5050
```

Se tudo foi configurado corretamente, uma mensagem semelhante a abaixo devera ser exibida.

```shell
WARNING! Your credentials are stored unencrypted in '/home/user/.docker/config.json'.
Configure a credential helper to remove this warning. See
https://docs.docker.com/go/credential-store/

Login Succeeded
```
