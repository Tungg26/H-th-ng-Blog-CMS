#!/bin/sh
set -eu

mysql --protocol=socket -uroot -p"${MYSQL_ROOT_PASSWORD}" -e \
  "GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO '${MYSQL_USER}'@'%';"
