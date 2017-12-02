#!/bin/bash

VERSION="1.1"

## Changelog
# 1.1 - Updated logging
# 1.0 - Private release

PORTS="21
23
1433
445
135
137
139
"

WHITELIST1="127.0.0"
WHITELIST2="107.191.100.146"
WHITELIST3="73.136.16.62"
WHITELIST4="98.194.110"

log_and_print ()
{
  echo "       " $1
  logger PortSmack - $1
}

if [ "$UID" != "0" ];then
echo "I am not root, lets try again with sudo..."
sudo $0
exit 0
fi

echo '#!/bin/bash' > /tmp/.response.sh
echo 'echo -e "I thought I smelled something phishy about you. Tisk Tisk...";' >> /tmp/.response.sh
chmod +x /tmp/.response.sh

while :
do
for each in $PORTS
do
if [ ! "`/usr/bin/lsof -i :$each`" ]; then
log_and_print "Port $each available, starting listener..."
netcat -v -l -p $each -e /tmp/.response.sh 2>&1 | sed -s 's/^/PortSmack\ -\ /g' | logger  &
log_and_print "Done."
fi

SUSPECT="`grep PortSmack /var/log/syslog | awk -F[ '{ print $3 }' | awk -F] '{ print $1 }' |sort | uniq | grep -v $WHITELIST1 | grep -v $WHITELIST2 | grep -v $WHITELIST3 | grep -v $WHITELIST4`"

for TARGET in $SUSPECT; do
if [ ! "`cat /etc/hosts.deny | grep $TARGET`" ]; then
    log_and_print "$TARGET: This guy is not in the hosts.deny list, adding..."
    echo "ALL: $TARGET" >> /etc/hosts.deny
 fi
 if [ ! "`iptables -L -n | grep $TARGET`" ];then
        log_and_print "$TARGET: This guy is not in iptables, adding..."
        iptables -A INPUT -s $TARGET -j DROP
 fi
done
done
done

exit 0