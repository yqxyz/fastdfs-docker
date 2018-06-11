#!/bin/bash
#set -e
n=0
if [ $# > 1 ] ; then
for arg in $*
do
if [ ${#arg} -gt 10 ]; then
TRACKER_SERVER[$n]=$arg
let n++
fi
done
fi
if [ "$1" = "monitor" ] ; then
  if [ -n "$TRACKER_SERVER" ] ; then  
    for SERVER in ${TRACKER_SERVER[*]}
    do
      echo "tracker_server=${SERVER}">>/etc/fdfs/client.conf
    done
  fi
  fdfs_monitor /etc/fdfs/client.conf
  exit 0
elif [ "$1" = "storage" ] ; then
  FASTDFS_MODE="storage"
else 
  FASTDFS_MODE="tracker"

fi

if [ -n "$PORT" ] ; then  
sed -i "s|^port=.*$|port=${PORT}|g" /etc/fdfs/"$FASTDFS_MODE".conf
fi

if [ -n "$TRACKER_SERVER" ] ; then  
for SERVER in ${TRACKER_SERVER[*]}
do
  echo "tracker_server=${SERVER}">>/etc/fdfs/storage.conf
  echo "tracker_server=${SERVER}">>/etc/fdfs/client.conf
  echo "tracker_server=${SERVER}">>/etc/fdfs//mod_fastdfs.conf
done
sed -i "s|http.server_port=.*$|http.server_port=${NGINX_PORT}|g" /etc/fdfs/storage.conf
sed -i "s|http.tracker_server_port=.*$|http.tracker_server_port=${NGINX_PORT}|g" /etc/fdfs/client.conf

fi

if [ -n "$GROUP_NAME" ] ; then  
sed -i "s|group_name=.*$|group_name=${GROUP_NAME}|g" /etc/fdfs/storage.conf
sed -i "s|group_name=.*$|group_name=${GROUP_NAME}|g" /etc/fdfs/mod_fastdfs.conf
fi 

if [ -n "$GROUP_COUNT" ] ; then

sed -i "s|group_count=.*$|group_count=${GROUP_COUNT}|g" /etc/fdfs//mod_fastdfs.conf
i=1
while(( $i<=$GROUP_COUNT ))
do
echo "[group$i]" >> /etc/fdfs/mod_fastdfs.conf
echo "group_name=group$i" >> /etc/fdfs/mod_fastdfs.conf
echo "storage_server_port=${PORT}" >> /etc/fdfs/mod_fastdfs.conf
echo "store_path_count=1" >> /etc/fdfs/mod_fastdfs.conf
echo "store_path0=${FASTDFS_BASE_PATH}" >> /etc/fdfs/mod_fastdfs.conf
let "i++"
done

fi

FASTDFS_LOG_FILE="${FASTDFS_BASE_PATH}/logs/${FASTDFS_MODE}d.log"
PID_NUMBER="${FASTDFS_BASE_PATH}/data/fdfs_${FASTDFS_MODE}d.pid"

echo "try to start the $FASTDFS_MODE node..."
if [ -f "$FASTDFS_LOG_FILE" ]; then 
	rm "$FASTDFS_LOG_FILE"
fi
# start the fastdfs node.	
fdfs_${FASTDFS_MODE}d /etc/fdfs/${FASTDFS_MODE}.conf start
if [ "$1" = "storage" ] ; then

if [ -n "$NGINX_PORT" ] ; then  
sed -i "s|listen       8080;.*$|listen       ${NGINX_PORT};|g" /etc/fdfs/nginx.conf
fi 

if [ "${FASTDFS_BASE_PATH}" != "/var/fdfs" ] ; then
sed -i "s|root /var/fdfs/data;.*$|root ${FASTDFS_BASE_PATH}/data;|g" /etc/fdfs/nginx.conf
fi


/usr/local/nginx/sbin/nginx

fi

# wait for pid file(important!),the max start time is 5 seconds,if the pid number does not appear in 5 seconds,start failed.
TIMES=5
while [ ! -f "$PID_NUMBER" -a $TIMES -gt 0 ]
do
    sleep 1s
	TIMES=`expr $TIMES - 1`
done
ln -s ${FASTDFS_BASE_PATH}/data ${FASTDFS_BASE_PATH}/data/M00

tail -f "$FASTDFS_LOG_FILE"
