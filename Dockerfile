FROM alpine as builder

LABEL maintainer "quentinyy@gmail.com"

ENV FASTDFS_PATH=/opt/fdfs


#get all the dependences
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories \
    && apk add --no-cache --virtual .build-deps git gcc libc-dev make wget perl bash pcre-dev zlib-dev

#compile the libfastcommon
WORKDIR ${FASTDFS_PATH}/libfastcommon

RUN git clone --depth=1 https://github.com/happyfish100/libfastcommon.git ${FASTDFS_PATH}/libfastcommon \
    && ./make.sh \
    && ./make.sh install 

#compile the fastdfs
WORKDIR ${FASTDFS_PATH}/fastdfs

RUN git clone --depth=1 https://github.com/happyfish100/fastdfs.git ${FASTDFS_PATH}/fastdfs \
    && ./make.sh \
    && ./make.sh install


#compile the nginx
WORKDIR ${FASTDFS_PATH}/nginx

RUN git clone --depth=1 https://github.com/happyfish100/fastdfs-nginx-module.git \
    && wget https://github.com/quentinyy/resource/raw/master/nginx-1.15.0.tar.gz \
    && tar -zxf nginx-1.15.0.tar.gz \
    && cd nginx-1.15.0 \
    && ./configure --add-module=${FASTDFS_PATH}/nginx/fastdfs-nginx-module/src \
    && make 

FROM alpine as prod

LABEL maintainer "quentinyy@gmail.com"

ENV FASTDFS_PATH=/opt/fdfs \
    FASTDFS_BASE_PATH=/var/fdfs \
    PORT= \
    NGINX_PORT=8080 \
    GROUP_NAME= \
    TRACKER_SERVER= \
    GROUP_COUNT= 

WORKDIR /root

COPY --from=0  ${FASTDFS_PATH} ${FASTDFS_PATH}

RUN cd ${FASTDFS_PATH}/libfastcommon \
    && sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories \
    && apk add --no-cache --virtual .build-deps make gcc libc-dev perl\
    && ./make.sh install \
    && cd ${FASTDFS_PATH}/fastdfs \
    && ./make.sh install \
    && cd ${FASTDFS_PATH}/nginx/nginx-1.15.0 \
    && make install \
    && rm -rf ${FASTDFS_PATH}/* \
    && apk del .build-deps \
    && apk add --no-cache pcre-dev zlib-dev bash

RUN  mkdir -p ${FASTDFS_BASE_PATH}/data

EXPOSE 22122 23000 8080 
VOLUME ["$FASTDFS_BASE_PATH", "/etc/fdfs","usr/local/nginx/conf"]   

COPY conf/*.* /etc/fdfs/

COPY conf/nginx.conf /usr/local/nginx/conf/

COPY start.sh /usr/bin/

#make the start.sh executable 
RUN chmod 777 /usr/bin/start.sh

ENTRYPOINT ["/usr/bin/start.sh"]
CMD ["tracker"]
