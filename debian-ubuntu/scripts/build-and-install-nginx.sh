#!/bin/bash

ROOT_DIR="$(realpath "$(dirname "$(readlink -f "$0")")"/../)"
cd "$ROOT_DIR"
. ./scripts/common.sh

CC_OPT_FLAG='-ffat-lto-objects -flto=4 -fPIC -fstack-protector-strong -g -march=native -O3 -pthread -Werror=format-security -Wformat'
DEVELOP_PACKAGES='libbrotli-dev libgeoip-dev libpcre3-dev libperl-dev libssl-dev libzstd-dev zlib1g-dev'
NGINX_VERSION='1.26.2'
RUNTIME_PACKAGES='geoip-bin geoip-database libbrotli1 libgeoip1 libpcre3 libperl5.* libssl3 libzstd1 zlib1g'
[ "$os_type" = 'debian' ] && CC_OPT_FLAG+=' -Wp,-D_FORTIFY_SOURCE=2'

# Clone brotli module
cd /tmp &&
	rm -rf ngx_brotli &&
	git clone https://github.com/google/ngx_brotli.git &&
	cd ngx_brotli &&
	git submodule update --init --recursive &&

	# Clone zstd module
	cd /tmp &&
	rm -rf zstd-nginx-module &&
	git clone https://github.com/tokers/zstd-nginx-module &&
	cd zstd-nginx-module &&
	git submodule update --init --recursive &&

	# Build nginx
	sudo apt-get install -y $DEVELOP_PACKAGES &&
	cd /tmp &&
	rm -rf nginx-$NGINX_VERSION nginx-$NGINX_VERSION.tar.gz* &&
	wget http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz &&
	tar -zxvf nginx-$NGINX_VERSION.tar.gz &&
	cd nginx-$NGINX_VERSION &&
	./configure \
		--add-module=../ngx_brotli \
		--add-module=../zstd-nginx-module \
		--conf-path=/etc/nginx/nginx.conf \
		--error-log-path=/var/log/nginx/error.log \
		--group=nginx \
		--http-client-body-temp-path=/var/cache/nginx/client_temp \
		--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
		--http-log-path=/var/log/nginx/access.log \
		--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
		--http-scgi-temp-path=/var/cache/nginx/scgi_temp \
		--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
		--lock-path=/var/run/nginx.lock \
		--modules-path=/usr/lib/nginx/modules \
		--pid-path=/var/run/nginx.pid \
		--prefix=/etc/nginx \
		--sbin-path=/usr/sbin/nginx \
		--user=nginx \
		--with-cc-opt="$CC_OPT_FLAG" \
		--with-compat \
		--with-file-aio \
		--with-http_addition_module \
		--with-http_auth_request_module \
		--with-http_dav_module \
		--with-http_degradation_module \
		--with-http_flv_module \
		--with-http_geoip_module \
		--with-http_geoip_module=dynamic \
		--with-http_gunzip_module \
		--with-http_gzip_static_module \
		--with-http_mp4_module \
		--with-http_perl_module \
		--with-http_perl_module=dynamic \
		--with-http_random_index_module \
		--with-http_realip_module \
		--with-http_secure_link_module \
		--with-http_slice_module \
		--with-http_ssl_module \
		--with-http_stub_status_module \
		--with-http_sub_module \
		--with-http_v2_module \
		--with-http_v3_module \
		--with-ld-opt='-ffat-lto-objects -flto=4 -pie -pthread -Wl,--as-needed -Wl,-Bsymbolic-functions -Wl,-z,now -Wl,-z,relro' \
		--with-mail \
		--with-mail_ssl_module \
		--without-poll_module \
		--without-select_module \
		--with-pcre-jit \
		--with-stream \
		--with-stream=dynamic \
		--with-stream_geoip_module \
		--with-stream_geoip_module=dynamic \
		--with-stream_realip_module \
		--with-stream_ssl_module \
		--with-stream_ssl_preread_module \
		--with-threads &&
	make -j$(nproc) &&
	sudo make install &&
	sudo mkdir -p /var/cache/nginx /var/log/nginx &&
	sudo apt-get remove -y --auto-remove --purge $DEVELOP_PACKAGES &&
	sudo apt-get install -y $RUNTIME_PACKAGES &&
	cd /tmp &&
	rm -rf nginx-$NGINX_VERSION ngx_brotli zstd-nginx-module &&

	# Configure nginx
	id -u nginx &>/dev/null || sudo useradd -r -s /sbin/nologin nginx &&
	sudo mkdir -p /etc/nginx/certs &&
	sudo openssl dhparam -dsaparam -out /etc/nginx/certs/dhparam.pem 4096 &&
	sudo rm -rf /etc/nginx/nginx.conf &&
	cd "$ROOT_DIR" &&
	sudo cp -r ./etc/nginx /etc/ &&
	sudo cp ./etc/systemd/system/nginx.service /etc/systemd/system/ &&
	sudo systemctl daemon-reload &&
	sudo systemctl enable nginx &&
	sudo systemctl restart nginx
