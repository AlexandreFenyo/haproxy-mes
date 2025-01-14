
build:
	docker build -t mes-haproxy:latest .

run: stop-rm
#	docker run --name mes-haproxy -t -i -e MES_DST_HOST=www.x.org -e MES_DST_PORT=443 -e MES_DST_EXTRA="ssl verify none" -e MES_MAX_RATE=20 -p 8000:8000 -p 8001:8001 --rm mes-haproxy
	docker run --name mes-haproxy -t -i -e MES_DST_HOST=host.docker.internal. -e MES_DST_PORT=8080 -e MES_MAX_RATE=20 -p 8000:8000 -p 8001:8001 --rm mes-haproxy

flood-0:
	while true; do curl http://localhost:8000 ; done

flood-1:
	while true; do curl http://localhost:8001 ; done

stats:
	docker exec -t -i mes-haproxy sh -c 'echo show table mes-backend | socat stdio /tmp/haproxy-master.sock'

run-web: stop-rm-web
	docker run -d --name mes-web -p 8080:8080 jmalloc/echo-server:latest

shell:
	docker run -t -i -e MES_DST_HOST=www.x.org -e MES_DST_PORT=80 -e MES_MAX_RATE=20 -p 8000:8000 -p 8001:8001 --rm mes-haproxy /bin/bash

exec:
	docker exec -t -i mes-haproxy /bin/bash

stop-rm:
	docker ps -a --filter "name=mes-haproxy" --format "{{.ID}}" | xargs docker stop
	docker ps -a --filter "name=mes-haproxy" --format "{{.ID}}" | xargs docker rm

stop-rm-web:
	docker ps -a --filter "name=mes-web" --format "{{.ID}}" | xargs docker stop
	docker ps -a --filter "name=mes-web" --format "{{.ID}}" | xargs docker rm

clean: stop-rm
	-docker rmi mes-haproxy
