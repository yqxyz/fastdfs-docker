FROM centos:7

LABEL maintainer "quentinyy@gmail.com"

ENV FASTDFS_PATH=/opt/fdfs \
    FASTDFS_BASE_PATH=/var/fdfs \
    PORT= \
    NGINX_PORT=8080 \
    GROUP_NAME= \
    TRACKER_SERVER= \
    GROUP_COUNT= 


#get all the dependences
RUN yum install -y git gcc make wget pcre pcre-devel zlib zlib-devel openssl openssl-devel

#create the dirs to store the files downloaded from internet
RUN mkdir -p ${FASTDFS_PATH}/libfastcommon \
    && mkdir -p ${FASTDFS_PATH}/fastdfs \
    && mkdir ${FASTDFS_BASE_PATH}

#compile the libfastcommon
WORKDIR ${FASTDFS_PATH}/libfastcommon

RUN git clone https://github.com/happyfish100/libfastcommon.git ${FASTDFS_PATH}/libfastcommon \
    && ./make.sh \
    && ./make.sh install \
    && rm -rf ${FASTDFS_PATH}/libfastcommon

#compile the fastdfs
WORKDIR ${FASTDFS_PATH}/fastdfs

RUN git clone https://github.com/happyfish100/fastdfs.git ${FASTDFS_PATH}/fastdfs \
    && ./make.sh \
    && ./make.sh install \
    && rm -rf ${FASTDFS_PATH}/fastdfs


#compile the nginx
WORKDIR ${FASTDFS_PATH}/nginx

RUN git clone https://github.com/happyfish100/fastdfs-nginx-module.git \
    && wget https://github.com/quentinyy/resource/raw/master/nginx-1.15.0.tar.gz \
    && tar -zxvf nginx-1.15.0.tar.gz \
    && cd nginx-1.15.0 \
    && ./configure --prefix=/usr/local/nginx --add-module=${FASTDFS_PATH}/nginx/fastdfs-nginx-module/src \
    && make \
    && make install \
    && rm -rf ${FASTDFS_PATH}/nginx

EXPOSE 22122 23000 8080 8888 
VOLUME ["$FASTDFS_BASE_PATH", "/etc/fdfs","usr/local/nginx/conf"]   

COPY conf/*.* /etc/fdfs/

COPY conf/nginx.conf /usr/local/nginx/conf/

COPY start.sh /usr/bin/

#make the start.sh executable 
RUN chmod 777 /usr/bin/start.sh

ENTRYPOINT ["/usr/bin/start.sh"]
CMD ["tracker"]
