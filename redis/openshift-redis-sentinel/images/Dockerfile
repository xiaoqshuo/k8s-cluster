FROM 49.4.114.57:1181/basic/centos:7.6.1810-tools

MAINTAINER guowei

COPY ./redis/bin/* /redis-data/bin/
COPY ./redis-master.conf /redis-data/conf/redis.conf
COPY ./run.sh /redis-data/conf/run.sh

RUN mkdir -p /redis-data/{data,conf} && \
    chmod 777 -R /opt/ /redis-data/ /tmp/ && \
    /bin/cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo 'Asia/Shanghai' > /etc/timezone

ENV LANG C.UTF-8

ENV PATH /redis-data/bin:$PATH

WORKDIR /redis-data

VOLUME /redis-data/data/

CMD [ "/redis-data/conf/run.sh" ]
ENTRYPOINT [ "bash", "-c"]
