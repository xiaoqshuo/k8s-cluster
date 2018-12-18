#!/bin/sh


/usr/sbin/nginx

/usr/local/bin/python "/usr/src/app/nginx-ldap-auth-daemon.py" --host 0.0.0.0 --port 8888

