
### haproxy-mes
PoC de QoS sur les requêtes web

Toutes les commandes à lancer pour tester ce PoC nécessitent d'être dans le répertoire haproxy-mes/docker et d'utiliser la commande `make`.

Les sources de ce PoC sont disponibles sur GitHub : [https://hub.docker.com/repository/docker/fenyoa/mes-haproxy](https://github.com/AlexandreFenyo/haproxy-mes)

### Récupération de l'image Docker de ce PoC
L'image OCI est disponible sur DockerHub : [https://hub.docker.com/repository/docker/fenyoa/mes-haproxy](https://hub.docker.com/repository/docker/fenyoa/mes-haproxy)

Récupération de l'image :
```
fenyo@mac docker % docker pull fenyoa/mes-haproxy:latest
latest: Pulling from fenyoa/mes-haproxy
Digest: sha256:b0fbf5aafffecc929b39109202f25ffc9c05f7e593924c3c85419f1b127af922
Status: Image is up to date for fenyoa/mes-haproxy:latest
docker.io/fenyoa/mes-haproxy:latest
```

### Lancer un test de ce PoC
## Lancer un serveur web local
Ce serveur local écoute sur le port TCP/8002 et représente le serveur backend vers lequel haproxy renvoie ses requêtes
```
fenyo@mac docker % make run-web    
docker ps -a --filter "name=mes-web" --format "{{.ID}}" | xargs docker stop
docker ps -a --filter "name=mes-web" --format "{{.ID}}" | xargs docker rm
docker run -d --name mes-web -p 8080:8080 jmalloc/echo-server:latest
169ffc41838a81b3bc5c5a96409ac57163357933b93d6da1a6015856ee9ea9ba
```
## Lancer haproxy écoutant sur les ports TCP/8000 et TCP/8001
Ce serveur haproxy renvoie les requêtes vers le serveur web local en privilégiant les requêtes arrivant sur le port TCP/8000 par rapport à celles arrivant sur le port TCP/8001. Il limite le taux maximum de requêtes à 20 par seconde.
```
fenyo@mac docker % make run
docker ps -a --filter "name=mes-haproxy" --format "{{.ID}}" | xargs docker stop
docker ps -a --filter "name=mes-haproxy" --format "{{.ID}}" | xargs docker rm
docker run --name mes-haproxy -t -i -e MES_DST_HOST=host.docker.internal. -e MES_DST_PORT=8080 -e MES_MAX_RATE=20 -p 8000:8000 -p 8001:8001 --rm mes-haproxy
CONFIGURATION FILE:
-- ------------------------------------------------------------
# Define global settings
global
    log stdout format raw local0 info
    maxconn 4096  # Maximum number of connections
    master-worker
    stats socket /tmp/haproxy-master.sock mode 600 level admin expose-fd listeners

# Default settings for all proxies
defaults
    log     global
    mode    http        # Operate in HTTP mode
    option  httplog     # Enable HTTP logging
    timeout connect 5s  # Max time to wait for a connection attempt to a server
    timeout client  30s # Max inactivity time on the client side
    timeout server  30s # Max inactivity time on the server side

backend mes-backend
    mode http
    # stick-table : size : nombre de ports de flux distincts observés (ici : 2 ports destination observés, à savoir 8000 et 8001)
    stick-table type integer size 2 expire 1s store http_req_rate(1s)
    # on groupe les requêtes par port d'écoute sur les fronts, pour décompter de manière distincte les taux de requêtes traitées en sortie par port d'écoute des fronts
    http-request track-sc0 dst_port
    # serveur cible de ce HAProxy
    server server1 host.docker.internal.:8080 
 
frontend mes-fast
    mode http
    # Les requêtes reçues sur le port 8000 sont traitées de manière prioritaire
    bind *:8000
    # on interdit les requêtes prioritaires si elles dépassent le budget max vers le serveur cible de ce HAProxy (20 requêtes par seconde)
    http-request return status 503 content-type "text/plain" lf-string "503 Service Unavailable\n\nThe service is temporarily unavailable. Please try again later." if { dst_port,table_http_req_rate(mes-backend) gt 20 }
    default_backend mes-backend
 
frontend mes-slow
    mode http
    # Les requêtes reçues sur le port 8001 sont traitées de manière non prioritaire
    bind *:8001
    # on calcule le budget restant pour les requêtes non prioritaires en soustrayant au budget total de sortie (20 requêtes par seconde) les taux de requêtes prioritaires et non prioritaires qui sont acheminées vers le serveur cible de ce HAproxy
    http-request set-var(req.back_slow_rate) 'int(8001),table_http_req_rate(mes-backend),neg()'
    http-request set-var(req.back_fast_rate) 'int(8000),table_http_req_rate(mes-backend),neg()'
    http-request set-var(req.back_max_minus_slow_minus_fast) 'int(20),add(req.back_fast_rate),add(req.back_slow_rate)'
    # on bloque les requêtes non prioritaires si le budget restant global vers le serveur est vide
    http-request return status 503 content-type "text/plain" lf-string "503 Service Unavailable\n\nThe service is temporarily unavailable. Please try again later." if { var(req.back_max_minus_slow_minus_fast) -m int lt 0 }
    default_backend mes-backend

-- ------------------------------------------------------------
[NOTICE]   (1) : Initializing new worker (11)
[NOTICE]   (1) : Loading success.
```

## Lancer une inondation de requêtes sur le port 8000
Cette commande fait une boucle sans fin pour interroger le serveur local au travers de haproxy, sur le port 8000.

```
fenyo@mac docker % make flood-0
while true; do curl http://localhost:8000 ; done
Request served by 169ffc41838a

GET / HTTP/1.1

Host: localhost:8000
Accept: */*
User-Agent: curl/8.7.1
Request served by 169ffc41838a

GET / HTTP/1.1
[...]
```

## Lancer une inondation de requêtes sur le port 8001
Cette commande fait une boucle sans fin pour interroger le serveur local au travers de haproxy, sur le port 8001.

```
fenyo@mac docker % make flood-1
while true; do curl http://localhost:8001 ; done
Request served by 169ffc41838a

GET / HTTP/1.1

Host: localhost:8001
Accept: */*
User-Agent: curl/8.7.1
Request served by 169ffc41838a

GET / HTTP/1.1
[...]
```

## Observer les statistiques haproxy
Lorsque les deux ports 8000 et 8001 sont sollicités simultanément, on constate que les requêtes privilégiées pour remplir le taux autorisé de 20 requêtes par seconde sont celles émises vers le port 8000.

```
fenyo@mac docker % make stats
docker exec -t -i mes-haproxy sh -c 'echo show table mes-backend | socat stdio /tmp/haproxy-master.sock'
# table: mes-backend, type: integer, size:2, used:2
0xaaaaf60a5b70: key=8001 use=0 exp=859 shard=0 http_req_rate(1000)=1
0xffff9c0574e0: key=8000 use=1 exp=998 shard=0 http_req_rate(1000)=21
```


