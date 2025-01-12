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
echo exec "$@"
exec "$@" -d
