#!/bin/sh
set -e

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- haproxy "$@"
fi

if [ "$1" = 'haproxy' ]; then
	shift # "haproxy"
	# if the user wants "haproxy", let's add a couple useful flags
	#   -W  -- "master-worker mode" (similar to the old "haproxy-systemd-wrapper"; allows for reload via "SIGUSR2")
	#   -db -- disables background mode
	set -- haproxy -W -db "$@"
fi

exec "$@"

exit 0

#!/bin/bash
set -e

# Remplacer les variables d'environnement dans le fichier template
cat /usr/local/etc/haproxy/haproxy-minimal.cfg > /tmp/haproxy.cfg
envsubst < /usr/local/etc/haproxy/haproxy-qos.cfg.template >> /tmp/haproxy.cfg

echo CONFIGURATION FILE:
echo -- ------------------------------------------------------------
cat /tmp/haproxy.cfg
echo -- ------------------------------------------------------------

# Exécuter l'exécutable HAProxy

#haproxy -f /tmp/haproxy.cfg

#echo FIN
#exit 0

echo exec "$@"
exec "$@"

############################################################
