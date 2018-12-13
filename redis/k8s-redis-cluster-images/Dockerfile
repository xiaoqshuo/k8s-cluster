FROM alpine:3.8

# redis docker images
# author xiaoqshuo
# date 2018 12 13

RUN apk add --no-cache 'su-exec>=0.2' sed bash ruby

ENV REDIS_VERSION 4.0.12
ENV REDIS_DOWNLOAD_URL http://download.redis.io/releases/redis-${REDIS_VERSION}.tar.gz
ENV TIME_ZONE Asiz/Shanghai

COPY redis-plus.sh /redis-plus.sh
COPY redis-4.0.3.gem /redis.gem
COPY rdoc-6.0.4.gem /rdoc.gem

# 下载redis 并且编译
RUN set -ex; \
	\
    apk update && apk add --no-cache --virtual .build-deps \
		coreutils \
		gcc \
		linux-headers \
		make \
		musl-dev \
		tzdata \
		tree \
		curl \
		# jq 是用来解析json 的,当然也可以用 grep 和 awk 配合来提取值
		jq \
	; \
	\
	# 设置时区
	# cp -r -f /usr/share/zoneinfo/Hongkong /etc/localtime ; \
	ln -snf /usr/share/zoneinfo/$TIME_ZONE /etc/localtime && echo $TIME_ZONE > /etc/timezone ;\
	echo -ne "Alpine Linux 3.8 image. (`uname -rsv`)\n" >> /root/.built ;\
	wget "$REDIS_DOWNLOAD_URL"; \
	# echo "$REDIS_DOWNLOAD_SHA *redis.tar.gz" | sha256sum -c -; \
	mkdir -p /usr/src/redis; \
	tar -xzf redis-$REDIS_VERSION.tar.gz -C /usr/src/redis --strip-components=1; \
	rm redis-$REDIS_VERSION.tar.gz; \
	\
	grep -q '^#define CONFIG_DEFAULT_PROTECTED_MODE 1$' /usr/src/redis/src/server.h; \
	sed -ri 's!^(#define CONFIG_DEFAULT_PROTECTED_MODE) 1$!\1 0!' /usr/src/redis/src/server.h; \
	grep -q '^#define CONFIG_DEFAULT_PROTECTED_MODE 0$' /usr/src/redis/src/server.h; \
	\
	make -C /usr/src/redis -j "$(nproc)"; \
	make -C /usr/src/redis install; \
	\
	cp -a /usr/src/redis/src/redis-trib.rb /usr/local/bin/redis-trib.rb ;\
	\
	rm -r /usr/src/redis; \
	\
    	apk del .build-deps ; \
	gem sources --add https://gems.ruby-china.com/ --remove https://rubygems.org/ ;\ 
	chmod +x /redis-plus.sh ;\
        chmod +x /usr/local/bin/redis-trib.rb ;\
        /bin/bash /redis-plus.sh


#  安装ruby环境  由于ruby的原因安装gem install redis的时候会稍微报点错,但是这个错误在docker里面会被捕捉到,所以放到shell 脚本里面去了
#  RUN gem sources --add https://gems.ruby-china.org/ --remove https://rubygems.org/
#  RUN gem install redis -V
#  RUN export PATH="$PATH:/usr/src/redis/src/"


EXPOSE 6379
EXPOSE 6380
EXPOSE 26379

VOLUME ["/data"]
WORKDIR /data

CMD ["redis-server", "/data/redis-cluster.conf"]

