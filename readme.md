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
