#!/bin/bash

PRODUCT_HOME=/u01/app/oracle/product/11.2.0

LISTENER_ORA=$PRODUCT_HOME/xe/network/admin/listener.ora
TNSNAMES_ORA=$PRODUCT_HOME/xe/network/admin/tnsnames.ora

function updateParameter() {
  local paramName="$1"
  local paramValue="$2"
  if [ ! -z "$paramValue" ]; then
    echo "Set parameter: $paramName=$paramValue"
    sed -i -r "/^$paramName=/d" $PRODUCT_HOME/xe/config/scripts/init.ora
    echo -e -n "\n$paramName=$paramValue" >> $PRODUCT_HOME/xe/config/scripts/init.ora
  fi
}
updateParameter processes $ORACLE_PROCESSES
updateParameter sessions $ORACLE_SESSIONS
updateParameter transactions $ORACLE_TRANSACTIONS

cp "${LISTENER_ORA}.tmpl" "$LISTENER_ORA" &&
sed -i "s/%hostname%/$HOSTNAME/g" "${LISTENER_ORA}" &&
sed -i "s/%port%/1521/g" "${LISTENER_ORA}" &&
cp "${TNSNAMES_ORA}.tmpl" "$TNSNAMES_ORA" &&
sed -i "s/%hostname%/$HOSTNAME/g" "${TNSNAMES_ORA}" &&
sed -i "s/%port%/1521/g" "${TNSNAMES_ORA}" &&

service oracle-xe start

export ORACLE_HOME=/u01/app/oracle/product/11.2.0/xe
export PATH=$ORACLE_HOME/bin:$PATH
export ORACLE_SID=XE

if [ "$ORACLE_ENABLE_XDB" = true ]; then
  echo "ALTER USER XDB ACCOUNT UNLOCK;" | sqlplus -s SYSTEM/oracle
  echo "ALTER USER XDB IDENTIFIED BY xdb;" | sqlplus -s SYSTEM/oracle
fi

if [ "$ORACLE_ALLOW_REMOTE" = true ]; then
  echo "alter system disable restricted session;" | sqlplus -s SYSTEM/oracle
fi

if [ "$ORACLE_DISABLE_ASYNCH_IO" = true ]; then
  echo "ALTER SYSTEM SET disk_asynch_io = FALSE SCOPE = SPFILE;" | sqlplus -s SYSTEM/oracle
  service oracle-xe restart
fi

for f in /docker-entrypoint-initdb.d/*; do
  case "$f" in
    *.sh)     echo "$0: running $f"; . "$f" ;;
    *.sql)    echo "$0: running $f"; echo "exit" | /u01/app/oracle/product/11.2.0/xe/bin/sqlplus "SYS/oracle" AS SYSDBA @"$f"; echo ;;
    *)        echo "$0: ignoring $f" ;;
  esac
  echo
done
