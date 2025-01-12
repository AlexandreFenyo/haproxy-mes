
build:
	docker build -t mes-haproxy:latest .

run: stop-rm
	docker run --name mes-haproxy -v $(PWD)/tst.cfg:/tmp/haproxy.cfg:ro -t -i -e MES_DST_HOST=www.x.org -e MES_DST_PORT=80 -e MES_MAX_RATE=20 -p 8000:8000 -p 8001:8001 --rm mes-haproxy haproxy -f /tmp/haproxy.cfg

shell:
	docker run -t -i -e MES_DST_HOST=www.x.org -e MES_DST_PORT=80 -e MES_MAX_RATE=20 -p 8000:8000 -p 8001:8001 --rm mes-haproxy /bin/bash

exec:
	docker exec -t -i mes-haproxy /bin/bash

stop-rm:
	docker ps -a --filter "name=mes-haproxy" --format "{{.ID}}" | xargs docker stop
	docker ps -a --filter "name=mes-haproxy" --format "{{.ID}}" | xargs docker rm

clean: stop-rm
	-docker rmi mes-haproxy

