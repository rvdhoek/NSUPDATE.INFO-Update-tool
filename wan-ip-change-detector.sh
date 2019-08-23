#!/bin/bash
PASSWORD="PASSWORD"
HOSTNAME="HOSTNAME"

log_history="/var/log/wan-ip.history"
wanip_file="/tmp/wan-ip.last"
#make file if not exist
if [ ! -f "$wanip_file" ]; then 
	touch $wanip_file
fi
#get ip adress ip4 and 6
wanipold=$(cat $wanip_file 2>/dev/null| awk 'NR==1')
wanipold6=$(cat $wanip_file 2>/dev/null| awk 'NR==2')

wanipnew=$(dig +short -4 myip.opendns.com @resolver1.opendns.com)
wanipnew6=$(dig +short -6 myip.opendns.com aaaa @resolver1.ipv6-sandbox.opendns.com)
#echo $wanipold
#echo $wanipold6

if expr "$wanipnew" : '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$' >/dev/null; then
 if [ "$wanipold" != "$wanipnew" ]||[ "$wanipold6" != "$wanipnew6" ] ; then
  RESULT=$(curl -s -k "https://""$HOSTNAME"":""$PASSWORD""@ipv4.nsupdate.info/nic/update")
  RESULT6=$(curl -s -k "https://""$HOSTNAME"":""$PASSWORD""@ipv6.nsupdate.info/nic/update")
echo $RESULT6

  echo $RESULT
  RCODE=$(echo "$RESULT" | cut -d " " -f 1)
  if [ "$RCODE" = "good" ] ; then errorstring="Good DNS update"
  fi
  if [ "$RCODE" = "badsys" ] ; then errorstring="Invalid service provider specified"
  fi
  if [ "$RCODE" = "!donator" ] ; then errorstring="PAY YOUR BILLS !!!!!!!"
  fi
  if [ "$RCODE" = "nochg" ] ; then errorstring="WARNING, Unneeded update of IP, repeting this might lead to a canceled account"
  fi
  if [ "$RCODE" = "badauth" ] ; then errorstring="Password or username is incorrect"
  fi
  if [ "$RCODE" = "notfqdn" ] ; then errorstring="Not a qualified hostname"
  fi
  if [ "$RCODE" = "nohost" ] ; then errorstring="No such hostname exists"
  fi
  if [ "$RCODE" = "!yours" ] ; then errorstring="No such host in YOUR account"
  fi
  if [ "$RCODE" = "numhost" ] ; then errorstring="To many or to few hosts specified"
  fi
  if [ "$RCODE" = "abuse" ] ; then errorstring="Your account is blocked because of update abuse"
  fi
  if [ "$RCODE" = "dnserr" ] ; then errorstring="DNS error"
  fi
  if [ "$RCODE" = "911" ] ; then errorstring="Server problems, check your DNS providers homepage"
  fi
  if [ "$RCODE" = "" ] ; then errorstring="No respons from server"
  fi
#Logfile
  echo "$(eval date +%Y-%m-%d"\ "%H:%M)"" Old: ""$wanipold"" New: ""$wanipnew" "  " "$wanipnew6" >> $log_history
  echo $HOSTNAME" says: ""$RESULT""  Errorstring: ""$errorstring" >> $log_history
  echo $HOSTNAME" update done"
	if [ -z "$wanipold" ] || [ -z "$wanipold6" ]; then 
		echo "$wanipnew" >> "$wanip_file"
                echo "$wanipnew6" >> "$wanip_file"
        fi

	if expr "$wanipold" : '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$' >/dev/null; then
		echo "$wanipnew" >> "$wanip_file"
                echo "$wanipnew6" >> "$wanip_file"
	fi
#Change iptables
#	if [ "$RCODE" = "good" ] ; then 
#	  sed "s/-A INPUT -s $wanipold /-A INPUT -s $wanipnew /" /etc/network/iptables  > /dev/null
#	  cp /etc/network/iptables /etc/iptables.conf
#	  /sbin/iptables-restore < /etc/network/iptables
#	  /etc/init.d/iptables restart
#	fi
else
  echo "No update needed"
fi 
fi

