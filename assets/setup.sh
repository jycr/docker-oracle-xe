#!/bin/bash

set -x

PRODUCT_VERSION="$1"
PRODUCT_URL="$2"
PRODUCT_SHA="$3"
PRODUCT_INSTAL_FILENAME="oracle-xe_${PRODUCT_VERSION}-2_amd64"

WORK_DIR="$(mktemp -d)"
pushd "$WORK_DIR"

wget https://github.com/wnameless/docker-oracle-xe-11g/raw/master/assets/oracle-xe_11.2.0-1.0_amd64.deba{a,b,c}
cat oracle-xe_*.deba* > "$PRODUCT_INSTAL_FILENAME.deb" &&

echo "${PRODUCT_SHA} $PRODUCT_INSTAL_FILENAME.deb" | sha512sum -c - &&

# TODO : switching to official package -> PRODUCT_URL=http://download.oracle.com/otn/linux/oracle11g/xe/oracle-xe-${PRODUCT_VERSION}-1.0.x86_64.rpm.zip
# cf. http://meandmyubuntulinux.blogspot.fr/2012/05/installing-oracle-11g-r2-express.html

#   curl -fsSL "${PRODUCT_URL}" -o "oracle-xe-${PRODUCT_VERSION}-1.0.x86_64.rpm.zip" &&
#   unzip oracle-xe-${PRODUCT_VERSION}-1.0.x86_64.rpm.zip
#   alien --scripts -d oracle-xe-11.2.0-1.0.x86_64.rpm


# avoid dpkg frontend dialog / frontend warnings
export DEBIAN_FRONTEND=noninteractive

ln -s /usr/bin/awk /bin/awk &&
mkdir /var/lock/subsys &&
mv /assets/chkconfig /sbin/chkconfig &&
chmod 755 /sbin/chkconfig &&

# Install Oracle
dpkg --install "$PRODUCT_INSTAL_FILENAME.deb" &&

popd

# Backup listener.ora as template
cp /u01/app/oracle/product/${PRODUCT_VERSION}/xe/network/admin/listener.ora /u01/app/oracle/product/${PRODUCT_VERSION}/xe/network/admin/listener.ora.tmpl &&
cp /u01/app/oracle/product/${PRODUCT_VERSION}/xe/network/admin/tnsnames.ora /u01/app/oracle/product/${PRODUCT_VERSION}/xe/network/admin/tnsnames.ora.tmpl &&

mv /assets/init.ora /u01/app/oracle/product/${PRODUCT_VERSION}/xe/config/scripts &&
mv /assets/initXETemp.ora /u01/app/oracle/product/${PRODUCT_VERSION}/xe/config/scripts &&

printf 8080\\n1521\\noracle\\noracle\\ny\\n | /etc/init.d/oracle-xe configure &&

echo "export ORACLE_HOME=/u01/app/oracle/product/${PRODUCT_VERSION}/xe" >> /etc/bash.bashrc &&
echo 'export PATH=$ORACLE_HOME/bin:$PATH' >> /etc/bash.bashrc &&
echo 'export ORACLE_SID=XE' >> /etc/bash.bashrc &&

# Install startup script for container
mv /assets/startup.sh /usr/sbin/startup.sh &&
chmod +x /usr/sbin/startup.sh &&

# Remove installation files
rm -r /assets/ "$WORK_DIR" &&

# Create initialization script folders
mkdir /docker-entrypoint-initdb.d

# Disable Oracle password expiration
export ORACLE_HOME=/u01/app/oracle/product/${PRODUCT_VERSION}/xe
export PATH=$ORACLE_HOME/bin:$PATH
export ORACLE_SID=XE

echo "ALTER PROFILE DEFAULT LIMIT PASSWORD_VERIFY_FUNCTION NULL;" | sqlplus -s SYSTEM/oracle
echo "alter profile DEFAULT limit password_life_time UNLIMITED;" | sqlplus -s SYSTEM/oracle
echo "alter user SYSTEM identified by oracle account unlock;" | sqlplus -s SYSTEM/oracle

exit $?
