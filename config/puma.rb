#!/usr/bin/env puma

threads 0, 4
# workers 3

bind  "unix:///var/tmp/b4u_prod.sock"
pidfile "/var/run/puma/b4u_prod.pid"
environment "production"
stdout_redirect "/var/log/puma/b4u_prod.log"