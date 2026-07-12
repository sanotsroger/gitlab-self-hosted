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

## Gitlab Runner

Comando que o `Gitlab` irá gerar para criar o `Runner`.

```shell
gitlab-runner register  --url http://172.16.0.2 --token {SEU_TOKEN_AQUI}
```

Segue abaixo as configurações utilizadas para o runner.

```shell
Enter the GitLab instance URL (for example, https://gitlab.com/): [Enter]
Enter a name for the runner. This is stored only in the local config.toml file: runner
Enter an executor: ssh, parallels, virtualbox, shell, custom, instance, docker, docker-windows, docker-autoscaler, docker+machine, kubernetes: docker
Enter the default Docker image (for example, ruby:3.3): alpine:3.21
```

Em seguida vamos alterar o arquivo `/etc/gitlab-runner/config.toml`

```shell
sed -i -E '
s/^concurrent = 1$/concurrent = 4/
/^check_interval = 0$/a connection_max_age = "15m0s"
s/^([[:space:]]*)url = "http:\/\/172.16.0.2"$/&\n\1clone_url = "http:\/\/172.16.0.2"/
s/^([[:space:]]*)executor = "docker"[[:space:]]*$/&\n\1request_concurrency = 2/
s/^([[:space:]]*)network_mtu = 0$/&\n\1network_mode = "gitlab-network"/
' /etc/gitlab-runner/config.toml
```
