# The perfect rootserver
# by zypr
# https://github.com/zypr/perfectrootserver
# Big thanks to https://github.com/andryyy/mailcow
# Compatible with Debian 8.x (jessie)

#################################
##  DO NOT MODIFY, JUST DON'T! ##
#################################

generatepw() {
        while [[ $pw == "" ]]; do
                pw=$(openssl rand -base64 30 | tr -d / | cut -c -24 | grep -P '(?=^.{8,255}$)(?=^[^\s]*$)(?=.*\d)(?=.*[A-Z])(?=.*[a-z])')
        done
        echo "$pw" && unset pw
}

installation() {
echo "${info} Starting installation!" | awk '{ print strftime("[%H:%M:%S] |"), $0 }'

cat > /etc/hosts <<END
127.0.0.1 localhost
::1 localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
END

if [[ -z $(dpkg --get-selections | grep -E "^dbus.*install$") ]]; then
	apt-get update -y >/dev/null 2>&1 && apt-get -y --force-yes install dbus >/dev/null 2>&1
fi

if [ ${USE_MAILSERVER} == '1' ]; then
	echo -e "${IPADR} mail.${MYDOMAIN} mail" >> /etc/hosts
	hostnamectl set-hostname mail
else
	echo -e "${IPADR} ${MYDOMAIN} $(echo ${MYDOMAIN} | cut -f 1 -d '.')" >> /etc/hosts
	hostnamectl set-hostname $(echo ${MYDOMAIN} | cut -f 1 -d '.')
fi

if [ ${USE_MAILSERVER} == '1' ]; then
	echo "mail.${MYDOMAIN}" > /etc/mailname
else
	echo "${MYDOMAIN}" > /etc/mailname
fi

echo "${info} Setting your hostname & timezone..." | awk '{ print strftime("[%H:%M:%S] |"), $0 }'
if [[ -f /usr/share/zoneinfo/${TIMEZONE} ]] ; then
	echo ${TIMEZONE} > /etc/timezone
	dpkg-reconfigure -f noninteractive tzdata >/dev/null 2>&1
	if [ "$?" -ne "0" ]; then
		echo "${error} Timezone configuration failed: dpkg returned exit code != 0" | awk '{ print strftime("[%H:%M:%S] |"), $0 }'
		exit 1
		fi
	else
		echo "${error} Cannot set your timezone: timezone is unknown" | awk '{ print strftime("[%H:%M:%S] |"), $0 }'
		exit 1
fi
#An accurate time is important
apt-get install ntp >/dev/null 2>&1

echo "${info} Installing prerequisites..." | awk '{ print strftime("[%H:%M:%S] |"), $0 }'
echo "${warn} Some of the tasks could take a long time, please be patient!" | awk '{ print strftime("[%H:%M:%S] |"), $0 }'

rm /etc/apt/sources.list
cat > /etc/apt/sources.list <<END
# Dotdeb
deb http://packages.dotdeb.org jessie all
deb-src http://packages.dotdeb.org jessie all

# Doveocot
deb http://xi.rename-it.nl/debian/ stable-auto/dovecot-2.3 main
END

cat > /etc/apt/sources.list.d/security.list <<END
deb http://security.debian.org/ stable/updates main contrib non-free
deb http://security.debian.org/ testing/updates main contrib non-free
END

cat > /etc/apt/sources.list.d/stable.list <<END
deb	http://ftp.debian.org/debian/ stable main contrib non-free
deb-src http://ftp.debian.org/debian/ stable main contrib non-free
END

cat > /etc/apt/sources.list.d/testing.list <<END
deb	http://ftp.debian.org/debian/ testing main contrib non-free
deb-src http://ftp.debian.org/debian/ testing main contrib non-free
END

cat > /etc/apt/sources.list.d/unstable.list <<END
deb	http://ftp.debian.org/debian/ unstable main contrib non-free
deb-src http://ftp.debian.org/debian/ unstable main contrib non-free
END

cat > /etc/apt/sources.list.d/experimental.list <<END
deb	http://ftp.debian.org/debian/ experimental main contrib non-free
deb-src http://ftp.debian.org/debian/ experimental main contrib non-free
END

cat > /etc/apt/preferences.d/security.pref <<END
Package: *
Pin: release l=Debian-Security
Pin-Priority: 1000
END

cat > /etc/apt/preferences.d/stable.pref <<END
Package: *
Pin: release a=stable
Pin-Priority: 900
END

cat > /etc/apt/preferences.d/testing.pref <<END
Package: *
Pin: release a=testing
Pin-Priority: 750
END

cat > /etc/apt/preferences.d/unstable.pref <<END
Package: *
Pin: release a=unstable
Pin-Priority: 50
END

cat > /etc/apt/preferences.d/experimental.pref <<END
Package: *
Pin: release a=experimental
Pin-Priority: 1
END

wget -O ~/sources/dovecot.key http://xi.rename-it.nl/debian/archive.key >/dev/null 2>&1 && apt-key add ~/sources/dovecot.key >/dev/null 2>&1
wget -O ~/sources/dotdeb.gpg http://www.dotdeb.org/dotdeb.gpg >/dev/null 2>&1 && apt-key add ~/sources/dotdeb.gpg >/dev/null 2>&1
apt-get update -y >/dev/null 2>&1 && apt-get -y upgrade >/dev/null 2>&1
apt-get -y --force-yes install aptitude ssl-cert whiptail apt-utils jq libc6-dev/stable >/dev/null 2>&1
DEBIAN_FRONTEND=noninteractive aptitude -y install apache2-threaded-dev apache2-utils apt-listchanges arj autoconf automake bison bsd-mailx build-essential bzip2 ca-certificates cabextract checkinstall curl dnsutils file flex git htop libapr1-dev libaprutil1 libaprutil1-dev libauthen-sasl-perl-Daemon libawl-php libcunit1-dev libcrypt-ssleay-perl libcurl4-openssl-dev libdbi-perl libgeoip-dev libio-socket-ssl-perl libio-string-perl liblockfile-simple-perl liblogger-syslog-perl libmail-dkim-perl libmail-spf-perl libmime-base64-urlsafe-perl libnet-dns-perl libnet-ident-perl libnet-LDAP-perl libnet1 libnet1-dev libpam-dev libpcre-ocaml-dev libpcre3 libpcre3-dev libreadline6-dev libtest-tempdir-perl libtool libuv-dev libwww-perl libxml2 libxml2-dev libxml2-utils libxslt1-dev libyaml-dev lzop mariadb-server mc memcached mlocate nettle-dev nomarch php-auth-sasl php-auth-sasl php-http-request php-http-request php-mail php-mail-mime php-mail-mimedecode php-net-dime php-net-smtp php-net-url php-pear php-soap php5 php5-apcu php5-cli php5-common php5-common php5-curl php5-dev php5-fpm php5-geoip php5-gd php5-igbinary php5-imap php5-intl php5-mcrypt php5-mysql php5-sqlite php5-xmlrpc php5-xsl pkg-config python-setuptools python-software-properties rkhunter software-properties-common subversion sudo unzip vim-nox zip zlib1g zlib1g-dbg zlib1g-de zoo >/dev/null 2>&1

if [ "$?" -ne "0" ]; then
	echo "${error} Package installation failed!" | awk '{ print strftime("[%H:%M:%S] |"), $0 }'
	exit 1
fi

mysqladmin -u root password ${MYSQL_ROOT_PASS}

sed -i 's/.*max_allowed_packet.*/max_allowed_packet = 128M/g' /etc/mysql/my.cnf
sed -i '32s/.*/innodb_file_per_table = 1\n&/' /etc/mysql/my.cnf
sed -i '33s/.*/innodb_additional_mem_pool_size = 50M\n&/' /etc/mysql/my.cnf
sed -i '34s/.*/innodb_thread_concurrency = 4\n&/' /etc/mysql/my.cnf
sed -i '35s/.*/innodb_flush_method = O_DSYNC\n&/' /etc/mysql/my.cnf
sed -i '36s/.*/innodb_flush_log_at_trx_commit = 0\n&/' /etc/mysql/my.cnf
sed -i '37s/.*/#innodb_buffer_pool_size = 2G #reserved RAM, reduce i\/o\n&/' /etc/mysql/my.cnf
sed -i '38s/.*/innodb_log_files_in_group = 2\n&/' /etc/mysql/my.cnf
sed -i '39s/.*/innodb_log_file_size = 32M\n&/' /etc/mysql/my.cnf
sed -i '40s/.*/innodb_log_buffer_size = 16M\n&/' /etc/mysql/my.cnf
sed -i '41s/.*/#innodb_table_locks = 0 #disable table lock, uncomment if you do not want to crash all applications, if one does\n&/' /etc/mysql/my.cnf

# Automated mysql_secure_installation
mysql -u root -p${MYSQL_ROOT_PASS} -e "DELETE FROM mysql.user WHERE User=''; DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1'); DROP DATABASE IF EXISTS test; FLUSH PRIVILEGES; DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'; FLUSH PRIVILEGES;" >/dev/null 2>&1

# Bash
cd ~/sources
mkdir bash && cd $_
echo "${info} Downloading GNU bash & latest security patches..." | awk '{ print strftime("[%H:%M:%S] |"), $0 }'
wget https://ftp.gnu.org/gnu/bash/bash-4.3.tar.gz >/dev/null 2>&1
for i in $(seq -f "%03g" 1 46); do wget http://ftp.gnu.org/gnu/bash/bash-4.3-patches/bash43-$i; done >/dev/null 2>&1
tar zxf bash-4.3.tar.gz && cd bash-4.3 >/dev/null 2>&1
echo "${info} Patching sourcefiles..." | awk '{ print strftime("[%H:%M:%S] |"), $0 }'
for i in ../bash43-[0-9][0-9][0-9]; do patch -p0 -s < $i; done
echo "${info} Compiling GNU bash..." | awk '{ print strftime("[%H:%M:%S] |"), $0 }'
./configure --prefix=/usr/local >/dev/null 2>&1 && make >/dev/null 2>&1 && make install >/dev/null 2>&1
cp -f /usr/local/bin/bash /bin/bash

# Nginx
cd ~/sources
echo "${info} Downloading Nginx Pagespeed..." | awk '{ print strftime("[%H:%M:%S] |"), $0 }'
wget https://github.com/pagespeed/ngx_pagespeed/archive/release-${NPS_VERSION}-beta.zip >/dev/null 2>&1
unzip -qq release-${NPS_VERSION}-beta.zip
cd ngx_pagespeed-release-${NPS_VERSION}-beta/
wget https://dl.google.com/dl/page-speed/psol/${NPS_VERSION}.tar.gz >/dev/null 2>&1
tar -xzf ${NPS_VERSION}.tar.gz
cd ~/sources
echo "${info} Downloading Nginx..." | awk '{ print strftime("[%H:%M:%S] |"), $0 }'
wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz >/dev/null 2>&1
tar -xzf nginx-${NGINX_VERSION}.tar.gz
cd nginx-${NGINX_VERSION}

echo "${info} Compiling Nginx..." | awk '{ print strftime("[%H:%M:%S] |"), $0 }'

./configure --prefix=/etc/nginx \
--sbin-path=/usr/sbin/nginx \
--conf-path=/etc/nginx/nginx.conf \
--error-log-path=/var/log/nginx/error.log \
--http-log-path=/var/log/nginx/access.log \
--pid-path=/var/run/nginx.pid \
--lock-path=/var/run/nginx.lock \
--http-client-body-temp-path=/var/lib/nginx/body \
--http-proxy-temp-path=/var/lib/nginx/proxy \
--http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
--http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
--http-scgi-temp-path=/var/lib/nginx/scgi \
--user=www-data \
--group=www-data \
--without-http_autoindex_module \
--without-http_browser_module \
--without-http_empty_gif_module \
--without-http_userid_module \
--without-http_split_clients_module \
--with-http_ssl_module \
--with-http_v2_module \
--with-http_realip_module \
--with-http_geoip_module \
--with-http_addition_module \
--with-http_sub_module \
--with-http_dav_module \
--with-http_flv_module \
--with-http_mp4_module \
--with-http_gunzip_module \
--with-http_gzip_static_module \
--with-http_random_index_module \
--with-http_secure_link_module \
--with-http_stub_status_module \
--with-http_auth_request_module \
--with-mail \
--with-mail_ssl_module \
--with-file-aio \
--with-ipv6 \
--with-debug \
--with-pcre \
--with-cc-opt='-O2 -g -pipe -Wall -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m64 -mtune=generic' \
--with-openssl=$HOME/sources/openssl-${OPENSSL_VERSION} \
--add-module=$HOME/sources/ngx_pagespeed-release-${NPS_VERSION}-beta >/dev/null 2>&1

# make the package
make >/dev/null 2>&1

# Create a .deb package
checkinstall --install=no -y >/dev/null 2>&1

# Install the package
echo "${info} Installing Nginx..." | awk '{ print strftime("[%H:%M:%S] |"), $0 }'
dpkg -i nginx_${NGINX_VERSION}-1_amd64.deb >/dev/null 2>&1
mv nginx_${NGINX_VERSION}-1_amd64.deb ../

# Create directories
mkdir -p /var/lib/nginx/body && cd $_
mkdir ../proxy
mkdir ../fastcgi
mkdir ../uwsgi
mkdir ../cgi
mkdir ../nps_cache
mkdir /var/log/nginx
mkdir /etc/nginx/sites-available && cd $_
mkdir ../sites-enabled
mkdir ../sites-custom
mkdir ../htpasswd
touch ../htpasswd/.htpasswd
mkdir ../logs
mkdir ../ssl
chown -R www-data:www-data /var/lib/nginx
chown www-data:www-data /etc/nginx/logs

# Install the Nginx service script
wget -O /etc/init.d/nginx --no-check-certificate https://raw.githubusercontent.com/Fleshgrinder/nginx-sysvinit-script/master/init >/dev/null 2>&1
chmod 0755 /etc/init.d/nginx
chown root:root /etc/init.d/nginx
update-rc.d nginx defaults

# Edit/create Nginx config files
echo "${info} Configuring Nginx..." | awk '{ print strftime("[%H:%M:%S] |"), $0 }'

rm -rf /etc/nginx/nginx.conf
cat > /etc/nginx/nginx.conf <<END
user www-data;
worker_processes auto;
pid /var/run/nginx.pid;

events {
	worker_connections  4024;
	multi_accept on;
	use epoll;
}

http {
		include       		/etc/nginx/mime.types;
		default_type  		application/octet-stream;
		server_tokens       off;
		keepalive_timeout   70;
		sendfile			on;
		send_timeout 60;
		tcp_nopush on;
		tcp_nodelay on;
		client_max_body_size 50m;
		client_body_timeout 15;
		client_header_timeout 15;
		client_body_buffer_size 1K;
		client_header_buffer_size 1k;
		large_client_header_buffers 4 8k;
		reset_timedout_connection on;
		server_names_hash_bucket_size 100;
		types_hash_max_size 2048;

		open_file_cache max=2000 inactive=20s;
		open_file_cache_valid 60s;
		open_file_cache_min_uses 5;
		open_file_cache_errors off;

		gzip on;
		gzip_static on;
		gzip_disable "msie6";
		gzip_vary on;
		gzip_proxied any;
		gzip_comp_level 6;
		gzip_min_length 1100;
		gzip_buffers 16 8k;
		gzip_http_version 1.1;
		gzip_types text/css text/javascript text/xml text/plain text/x-component application/javascript application/x-javascript application/json application/xml application/rss+xml font/truetype application/x-font-ttf font/opentype application/vnd.ms-fontobject image/svg+xml;

		log_format main     '\$remote_addr - \$remote_user [\$time_local] "\$request" '
							'\$status \$body_bytes_sent "\$http_referer" '
							'"\$http_user_agent" "\$http_x_forwarded_for"';

		access_log		logs/access.log main buffer=16k;
		error_log       	logs/error.log;

		map \$http_referer \$bad_referer {
			default 0;
			~(?i)(adult|babes|click|diamond|forsale|girl|jewelry|love|nudit|organic|poker|porn|poweroversoftware|sex|teen|webcam|zippo|casino|replica) 1;
		}

		map \$http_cookie \$cache_uid {
		  default nil;
		  ~SESS[[:alnum:]]+=(?<session_id>[[:alnum:]]+) \$session_id;
		}
		
		map \$request_method \$no_cache {
		  default 1;
		  HEAD 0;
		}

		include			/etc/nginx/sites-enabled/*.conf;
}
END

# SSL certificate
if [ ${CLOUDFLARE} == '0' ] && [ ${USE_VALID_SSL} == '1' ]; then
	echo "${info} Creating valid SSL certificates..." | awk '{ print strftime("[%H:%M:%S] |"), $0 }'
	git clone https://github.com/letsencrypt/letsencrypt ~/sources/letsencrypt -q
	cd ~/sources/letsencrypt
	if [ ${USE_MAILSERVER} == '1' ]; then
		./letsencrypt-auto --agree-tos --renew-by-default --non-interactive --standalone --email ${SSLMAIL} --rsa-key-size ${RSA_KEY_SIZE} -d ${MYDOMAIN} -d www.${MYDOMAIN} -d mail.${MYDOMAIN} -d autodiscover.${MYDOMAIN} -d autoconfig.${MYDOMAIN} -d dav.${MYDOMAIN} certonly >/dev/null 2>&1
	else
		./letsencrypt-auto --agree-tos --renew-by-default --non-interactive --standalone --email ${SSLMAIL} --rsa-key-size ${RSA_KEY_SIZE} -d ${MYDOMAIN} -d www.${MYDOMAIN} certonly >/dev/null 2>&1
	fi
	ln -s /etc/letsencrypt/live/${MYDOMAIN}/fullchain.pem /etc/nginx/ssl/${MYDOMAIN}.pem
	ln -s /etc/letsencrypt/live/${MYDOMAIN}/privkey.pem /etc/nginx/ssl/${MYDOMAIN}.key.pem
else
	echo "${info} Creating self-signed SSL certificates..." | awk '{ print strftime("[%H:%M:%S] |"), $0 }'
	openssl ecparam -genkey -name secp384r1 -out /etc/nginx/ssl/${MYDOMAIN}.key.pem >/dev/null 2>&1
	openssl req -new -sha256 -key /etc/nginx/ssl/${MYDOMAIN}.key.pem -out /etc/nginx/ssl/csr.pem -subj "/C=/ST=/L=/O=/OU=/CN=*.${MYDOMAIN}" >/dev/null 2>&1
	openssl req -x509 -days 365 -key /etc/nginx/ssl/${MYDOMAIN}.key.pem -in /etc/nginx/ssl/csr.pem -out /etc/nginx/ssl/${MYDOMAIN}.pem >/dev/null 2>&1
fi

HPKP1=$(openssl x509 -pubkey < /etc/nginx/ssl/${MYDOMAIN}.pem | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64)
HPKP2=$(openssl rand -base64 32)

echo "${info} Creating strong Diffie-Hellman parameters, please wait..." | awk '{ print strftime("[%H:%M:%S] |"), $0 }'
openssl dhparam -out /etc/nginx/ssl/dh.pem ${RSA_KEY_SIZE} >/dev/null 2>&1

# Create server config
rm -rf /etc/nginx/sites-available/${MYDOMAIN}.conf
cat > /etc/nginx/sites-available/${MYDOMAIN}.conf <<END
server {
			listen 				80 default_server;
			server_name 		${IPADR} ${MYDOMAIN};
			return 301 			https://${MYDOMAIN}\$request_uri;
}

server {
			listen 				443;
			server_name 		${IPADR} www.${MYDOMAIN} mail.${MYDOMAIN};
			return 301 			https://${MYDOMAIN}\$request_uri;
}

server {
			listen 				443 ssl http2 default deferred;
			server_name 		${MYDOMAIN};

			root 				/etc/nginx/html;
			index 				index.php index.html index.htm;

			charset 			utf-8;

			error_page 404 		/index.php;

			ssl_certificate 	ssl/${MYDOMAIN}.pem;
			ssl_certificate_key ssl/${MYDOMAIN}.key.pem;
			#ssl_trusted_certificate ssl/${MYDOMAIN}.pem;
			ssl_dhparam	     	ssl/dh.pem;
			ssl_ecdh_curve		secp384r1;
			ssl_session_cache   shared:SSL:10m;
			ssl_session_timeout 10m;
			ssl_session_tickets off;
			ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;
			ssl_prefer_server_ciphers on;
			ssl_buffer_size 	1400;

			#ssl_stapling 		on;
			#ssl_stapling_verify on;
			#resolver 			8.8.8.8 8.8.4.4 208.67.222.222 208.67.220.220 valid=60s;
			#resolver_timeout 	2s;

			ssl_ciphers 		"ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!3DES:!MD5:!PSK";

			#add_header 		Strict-Transport-Security "max-age=63072000; includeSubdomains; preload";
			##add_header 		Public-Key-Pins 'pin-sha256="PIN1"; pin-sha256="PIN2"; max-age=5184000; includeSubDomains';
			add_header 			Cache-Control "public";
			add_header 			X-Frame-Options SAMEORIGIN;
			add_header 			Alternate-Protocol  443:npn-http/2;
			add_header 			X-Content-Type-Options nosniff;
			add_header 			X-XSS-Protection "1; mode=block";
			add_header 			X-Permitted-Cross-Domain-Policies "master-only";
			add_header 			"X-UA-Compatible" "IE=Edge";
			add_header 			"Access-Control-Allow-Origin" "*";
			add_header 			Content-Security-Policy "script-src 'self' 'unsafe-inline' 'unsafe-eval' *.youtube.com maps.gstatic.com *.googleapis.com *.google-analytics.com cdnjs.cloudflare.com assets.zendesk.com connect.facebook.net; frame-src 'self' *.youtube.com assets.zendesk.com *.facebook.com s-static.ak.facebook.com tautt.zendesk.com; object-src 'self'";

			pagespeed 			on;
			pagespeed 			EnableFilters collapse_whitespace;
			pagespeed 			EnableFilters canonicalize_javascript_libraries;
			pagespeed 			EnableFilters combine_css;
			pagespeed 			EnableFilters combine_javascript;
			pagespeed 			EnableFilters elide_attributes;
			pagespeed 			EnableFilters extend_cache;
			pagespeed 			EnableFilters flatten_css_imports;
			pagespeed 			EnableFilters lazyload_images;
			pagespeed 			EnableFilters rewrite_javascript;
			pagespeed 			EnableFilters rewrite_images;
			pagespeed 			EnableFilters insert_dns_prefetch;
			pagespeed 			EnableFilters prioritize_critical_css;

			pagespeed 			FetchHttps enable,allow_self_signed;
			pagespeed 			FileCachePath /var/lib/nginx/nps_cache;
			pagespeed 			RewriteLevel CoreFilters;
			pagespeed 			CssFlattenMaxBytes 5120;
			pagespeed 			LogDir /var/log/pagespeed;
			pagespeed 			EnableCachePurge on;
			pagespeed 			PurgeMethod PURGE;
			pagespeed 			DownstreamCachePurgeMethod PURGE;
			pagespeed 			DownstreamCachePurgeLocationPrefix http://127.0.0.1:80/;
			pagespeed 			DownstreamCacheRewrittenPercentageThreshold 95;
			pagespeed 			LazyloadImagesAfterOnload on;
			pagespeed 			LazyloadImagesBlankUrl "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7";

			pagespeed 			MemcachedThreads 1;
			pagespeed 			MemcachedServers "localhost:11211";
			pagespeed 			MemcachedTimeoutUs 100000;
			pagespeed 			RespectVary on;

			pagespeed 			Disallow "*/pma/*";

			# This will correctly rewrite your subresources with https:// URLs and thus avoid mixed content warnings.
			# Note, that you should only enable this option if you are behind a load-balancer that will set this header,
			# otherwise your users will be able to set the protocol PageSpeed uses to interpret the request.
			#
			#pagespeed 			RespectXForwardedProto on;

			auth_basic_user_file htpasswd/.htpasswd;

			location ~ \.php\$ {
				fastcgi_split_path_info ^(.+\.php)(/.+)\$;
				if (!-e \$document_root\$fastcgi_script_name) {
					return 404;
			  	}
				try_files \$fastcgi_script_name =404;
				fastcgi_param PATH_INFO \$fastcgi_path_info;
				fastcgi_param PATH_TRANSLATED \$document_root\$fastcgi_path_info;
				fastcgi_param APP_ENV production;
				fastcgi_pass unix:/var/run/php5-fpm.sock;
				fastcgi_index index.php;
				include fastcgi.conf;
				fastcgi_intercept_errors off;
				fastcgi_ignore_client_abort off;
				fastcgi_buffers 256 16k;
				fastcgi_buffer_size 128k;
				fastcgi_connect_timeout 3s;
				fastcgi_send_timeout 120s;
				fastcgi_read_timeout 120s;
				fastcgi_busy_buffers_size 256k;
				fastcgi_temp_file_write_size 256k;
			}

			include /etc/nginx/sites-custom/*.conf;

			location / {
			   	# Uncomment, if you need to remove index.php from the
				# URL. Usefull if you use Codeigniter, Zendframework, etc.
				# or just need to remove the index.php
				#
			   	#try_files \$uri \$uri/ /index.php?\$args;
			}

			location ~* /\.(?!well-known\/) {
			    deny all;
			    access_log off;
				log_not_found off;
			}

			location ~* (?:\.(?:bak|conf|dist|fla|in[ci]|log|psd|sh|sql|sw[op])|~)$ {
			    deny all;
			    access_log off;
				log_not_found off;
			}

			location = /favicon.ico {
				access_log off;
				log_not_found off;
			}
				
			location = /robots.txt {
				allow all;
				access_log off;
				log_not_found off;
			}

			location ~* ^.+\.(css|js)\$ {
				rewrite ^(.+)\.(\d+)\.(css|js)\$ \$1.\$3 last;
				expires 30d;
				access_log off;
				log_not_found off;
				add_header Pragma public;
				add_header Cache-Control "max-age=2592000, public";
			}

			location ~* \.(asf|asx|wax|wmv|wmx|avi|bmp|class|divx|doc|docx|eot|exe|gif|gz|gzip|ico|jpg|jpeg|jpe|mdb|mid|midi|mov|qt|mp3|m4a|mp4|m4v|mpeg|mpg|mpe|mpp|odb|odc|odf|odg|odp|ods|odt|ogg|ogv|otf|pdf|png|pot|pps|ppt|pptx|ra|ram|svg|svgz|swf|tar|t?gz|tif|tiff|ttf|wav|webm|wma|woff|wri|xla|xls|xlsx|xlt|xlw|zip)\$ {
				expires 30d;
				access_log off;
				log_not_found off;
				add_header Pragma public;
				add_header Cache-Control "max-age=2592000, public";
			}

			if (\$http_user_agent ~* "FeedDemon|JikeSpider|Indy Library|Alexa Toolbar|AskTbFXTV|AhrefsBot|CrawlDaddy|CoolpadWebkit|Java|Feedly|UniversalFeedParser|ApacheBench|Microsoft URL Control|Swiftbot|ZmEu|oBot|jaunty|Python-urllib|lightDeckReports Bot|YYSpider|DigExt|YisouSpider|HttpClient|MJ12bot|heritrix|EasouSpider|Ezooms|Scrapy") {
            	return 403;
            }
}
END

ln -s /etc/nginx/sites-available/${MYDOMAIN}.conf /etc/nginx/sites-enabled/${MYDOMAIN}.conf

if [ ${CLOUDFLARE} == '0' ] && [ ${USE_VALID_SSL} == '1' ]; then
	sed -i 's/#ssl/ssl/g' /etc/nginx/sites-available/${MYDOMAIN}.conf
	sed -i 's/#resolver/resolver/g' /etc/nginx/sites-available/${MYDOMAIN}.conf
	sed -i 's/#add/add/g' /etc/nginx/sites-available/${MYDOMAIN}.conf
fi

# Configure PHP
echo "${info} Configuring PHP..." | awk '{ print strftime("[%H:%M:%S] |"), $0 }'
sed -i 's/.*disable_functions =.*/disable_functions = pcntl_alarm,pcntl_fork,pcntl_waitpid,pcntl_wait,pcntl_wifexited,pcntl_wifstopped,pcntl_wifsignaled,pcntl_wexitstatus,pcntl_wtermsig,pcntl_wstopsig,pcntl_signal,pcntl_signal_dispatch,pcntl_get_last_error,pcntl_strerror,pcntl_sigprocmask,pcntl_sigwaitinfo,pcntl_sigtimedwait,pcntl_exec,pcntl_getpriority,pcntl_setpriority,escapeshellarg,passthru,proc_close,proc_get_status,proc_nice,proc_open,proc_terminate,/' /etc/php5/fpm/php.ini
sed -i 's/.*ignore_user_abort =.*/ignore_user_abort = Off/' /etc/php5/fpm/php.ini
sed -i 's/.*expose_php =.*/expose_php = Off/' /etc/php5/fpm/php.ini
sed -i 's/.*post_max_size =.*/post_max_size = 15M/' /etc/php5/fpm/php.ini
sed -i 's/.*default_charset =.*/default_charset = "UTF-8"/' /etc/php5/fpm/php.ini
sed -i 's/.*cgi.fix_pathinfo=.*/cgi.fix_pathinfo=1/' /etc/php5/fpm/php.ini
sed -i 's/.*upload_max_filesize =.*/upload_max_filesize = 15M/' /etc/php5/fpm/php.ini
sed -i 's/.*default_socket_timeout =.*/default_socket_timeout = 30/' /etc/php5/fpm/php.ini
sed -i 's/.*date.timezone =.*/date.timezone = Europe\/Berlin/' /etc/php5/fpm/php.ini
sed -i 's/.*mysql.allow_persistent =.*/mysql.allow_persistent = Off/' /etc/php5/fpm/php.ini
sed -i 's/.*session.cookie_httponly =.*/session.cookie_httponly = 1/' /etc/php5/fpm/php.ini

# Configure PHP-FPM
sed -i 's/.*emergency_restart_threshold =.*/emergency_restart_threshold = 10/' /etc/php5/fpm/php-fpm.conf
sed -i 's/.*emergency_restart_interval =.*/emergency_restart_interval = 1m/' /etc/php5/fpm/php-fpm.conf
sed -i 's/.*process_control_timeout =.*/process_control_timeout = 10/' /etc/php5/fpm/php-fpm.conf
sed -i 's/.*events.mechanism =.*/events.mechanism = epoll/' /etc/php5/fpm/php-fpm.conf
sed -i 's/.*listen.mode =.*/listen.mode = 0666/' /etc/php5/fpm/pool.d/www.conf
sed -i 's/.*listen.allowed_clients =.*/listen.allowed_clients = 127.0.0.1/' /etc/php5/fpm/pool.d/www.conf
sed -i 's/.*pm.max_children =.*/pm.max_children = 50/' /etc/php5/fpm/pool.d/www.conf
sed -i 's/.*pm.start_servers =.*/pm.start_servers = 15/' /etc/php5/fpm/pool.d/www.conf
sed -i 's/.*pm.min_spare_servers =.*/pm.min_spare_servers = 5/' /etc/php5/fpm/pool.d/www.conf
sed -i 's/.*pm.max_spare_servers =.*/pm.max_spare_servers = 25/' /etc/php5/fpm/pool.d/www.conf
sed -i 's/.*pm.process_idle_timeout =.*/pm.process_idle_timeout = 60s;/' /etc/php5/fpm/pool.d/www.conf
sed -i 's/.*request_terminate_timeout =.*/request_terminate_timeout = 360/' /etc/php5/fpm/pool.d/www.conf
sed -i 's/.*security.limit_extensions =.*/security.limit_extensions = .php/' /etc/php5/fpm/pool.d/www.conf
sed -i 's/.*php_flag[display_errors] =.*/php_flag[display_errors] = off/' /etc/php5/fpm/pool.d/www.conf
sed -i 's/.*php_admin_value[error_log] =.*/php_admin_value[error_log] = \/var\/log\/fpm5-php.www.log/' /etc/php5/fpm/pool.d/www.conf
sed -i 's/.*php_admin_flag[log_errors] =.*/php_admin_flag[log_errors] = on/' /etc/php5/fpm/pool.d/www.conf
sed -i 's/.*php_admin_value[memory_limit] =.*/php_admin_value[memory_limit] = 128M/' /etc/php5/fpm/pool.d/www.conf
echo -e "php_flag[display_errors] = off" >> /etc/php5/fpm/pool.d/www.conf

# Configure APCu
rm -rf /etc/php5/mods-available/apcu.ini
rm -rf /etc/php5/mods-available/20-apcu.ini

cat > /etc/php5/mods-available/apcu.ini <<END
extension=apcu.so
apc.enabled=1
apc.stat = "0"
apc.max_file_size = "1M"
apc.localcache = "1"
apc.localcache.size = "256"
apc.shm_segments = "1"
apc.ttl = "3600"
apc.user_ttl = "7200"
apc.enable_cli=0
apc.gc_ttl = "3600"
apc.cache_by_default = "1"
apc.filters = ""
apc.write_lock = "1"
apc.num_files_hint= "512"
apc.user_entries_hint="4096"
apc.shm_size = "256M"
apc.mmap_file_mask=/tmp/apc.XXXXXX
apc.include_once_override = "0"
apc.file_update_protection="2"
apc.canonicalize = "1"
apc.report_autofilter="0"
apc.stat_ctime="0"
END

ln -s /etc/php5/mods-available/apcu.ini /etc/php5/mods-available/20-apcu.ini


# Restart FPM & Nginx
systemctl -q start nginx.service
systemctl -q restart php5-fpm.service

# phpMyAdmin
if [ $USE_PMA == '1' ]; then
	echo "${info} Installing phpMyAdmin..." | awk '{ print strftime("[%H:%M:%S] |"), $0 }'
	htpasswd -b /etc/nginx/htpasswd/.htpasswd ${PMA_HTTPAUTH_USER} ${PMA_HTTPAUTH_PASS} >/dev/null 2>&1
	cd /usr/local
	git clone -b STABLE https://github.com/phpmyadmin/phpmyadmin.git -q
	mkdir phpmyadmin/save
	mkdir phpmyadmin/upload
	chmod 0700 phpmyadmin/save
	chmod g-s phpmyadmin/save
	chmod 0700 phpmyadmin/upload
	chmod g-s phpmyadmin/upload
	mysql -u root -p${MYSQL_ROOT_PASS} mysql < phpmyadmin/sql/create_tables.sql >/dev/null 2>&1
	mysql -u root -p${MYSQL_ROOT_PASS} -e "GRANT USAGE ON mysql.* TO '${MYSQL_PMADB_USER}'@'${MYSQL_HOSTNAME}' IDENTIFIED BY '${MYSQL_PMADB_PASS}'; GRANT SELECT ( Host, User, Select_priv, Insert_priv, Update_priv, Delete_priv, Create_priv, Drop_priv, Reload_priv, Shutdown_priv, Process_priv, File_priv, Grant_priv, References_priv, Index_priv, Alter_priv, Show_db_priv, Super_priv, Create_tmp_table_priv, Lock_tables_priv, Execute_priv, Repl_slave_priv, Repl_client_priv ) ON mysql.user TO '${MYSQL_PMADB_USER}'@'${MYSQL_HOSTNAME}'; GRANT SELECT ON mysql.db TO '${MYSQL_PMADB_USER}'@'${MYSQL_HOSTNAME}'; GRANT SELECT (Host, Db, User, Table_name, Table_priv, Column_priv) ON mysql.tables_priv TO '${MYSQL_PMADB_USER}'@'${MYSQL_HOSTNAME}'; GRANT SELECT, INSERT, DELETE, UPDATE, ALTER ON ${MYSQL_PMADB_NAME}.* TO '${MYSQL_PMADB_USER}'@'${MYSQL_HOSTNAME}'; FLUSH PRIVILEGES;" >/dev/null 2>&1
	cat > phpmyadmin/config.inc.php <<END
<?php
\$cfg['blowfish_secret'] = '$PMA_BFSECURE_PASS';
\$i = 0;
\$i++;
\$cfg['UploadDir'] = 'upload';
\$cfg['SaveDir'] = 'save';
\$cfg['ForceSSL'] = true;
\$cfg['ExecTimeLimit'] = 300;
\$cfg['VersionCheck'] = false;
\$cfg['NavigationTreeEnableGrouping'] = false;
\$cfg['AllowArbitraryServer'] = true;
\$cfg['AllowThirdPartyFraming'] = true;
\$cfg['ShowServerInfo'] = false;
\$cfg['ShowDbStructureCreation'] = true;
\$cfg['ShowDbStructureLastUpdate'] = true;
\$cfg['ShowDbStructureLastCheck'] = true;
\$cfg['UserprefsDisallow'] = array(
    'ShowServerInfo',
    'ShowDbStructureCreation',
    'ShowDbStructureLastUpdate',
    'ShowDbStructureLastCheck',
    'Export/quick_export_onserver',
    'Export/quick_export_onserver_overwrite',
    'Export/onserver');
\$cfg['Import']['charset'] = 'utf-8';
\$cfg['Export']['quick_export_onserver'] = true;
\$cfg['Export']['quick_export_onserver_overwrite'] = true;
\$cfg['Export']['compression'] = 'gzip';
\$cfg['Export']['charset'] = 'utf-8';
\$cfg['Export']['onserver'] = true;
\$cfg['Export']['sql_drop_database'] = true;
\$cfg['DefaultLang'] = 'en';
\$cfg['ServerDefault'] = 1;
\$cfg['Servers'][\$i]['auth_type'] = 'cookie';
\$cfg['Servers'][\$i]['auth_http_realm'] = 'phpMyAdmin Login';
\$cfg['Servers'][\$i]['host'] = '${MYSQL_HOSTNAME}';
\$cfg['Servers'][\$i]['connect_type'] = 'tcp';
\$cfg['Servers'][\$i]['compress'] = false;
\$cfg['Servers'][\$i]['extension'] = 'mysqli';
\$cfg['Servers'][\$i]['AllowNoPassword'] = false;
\$cfg['Servers'][\$i]['controluser'] = '$MYSQL_PMADB_USER';
\$cfg['Servers'][\$i]['controlpass'] = '$MYSQL_PMADB_PASS';
\$cfg['Servers'][\$i]['pmadb'] = '$MYSQL_PMADB_NAME';
\$cfg['Servers'][\$i]['bookmarktable'] = 'pma__bookmark';
\$cfg['Servers'][\$i]['relation'] = 'pma__relation';
\$cfg['Servers'][\$i]['table_info'] = 'pma__table_info';
\$cfg['Servers'][\$i]['table_coords'] = 'pma__table_coords';
\$cfg['Servers'][\$i]['pdf_pages'] = 'pma__pdf_pages';
\$cfg['Servers'][\$i]['column_info'] = 'pma__column_info';
\$cfg['Servers'][\$i]['history'] = 'pma__history';
\$cfg['Servers'][\$i]['table_uiprefs'] = 'pma__table_uiprefs';
\$cfg['Servers'][\$i]['tracking'] = 'pma__tracking';
\$cfg['Servers'][\$i]['userconfig'] = 'pma__userconfig';
\$cfg['Servers'][\$i]['recent'] = 'pma__recent';
\$cfg['Servers'][\$i]['favorite'] = 'pma__favorite';
\$cfg['Servers'][\$i]['users'] = 'pma__users';
\$cfg['Servers'][\$i]['usergroups'] = 'pma__usergroups';
\$cfg['Servers'][\$i]['navigationhiding'] = 'pma__navigationhiding';
\$cfg['Servers'][\$i]['savedsearches'] = 'pma__savedsearches';
\$cfg['Servers'][\$i]['central_columns'] = 'pma__central_columns';
\$cfg['Servers'][\$i]['designer_settings'] = 'pma__designer_settings';
\$cfg['Servers'][\$i]['export_templates'] = 'pma__export_templates';
\$cfg['Servers'][\$i]['hide_db'] = 'information_schema';
?>
END
	if [ ${PMA_RESTRICT} == '1' ]; then
		sed -i "64s/.*/\$cfg['Servers'][\$i]['AllowDeny']['order'] = 'deny,allow';\n&/" /usr/local/phpmyadmin/config.inc.php
		sed -i "65s/.*/\$cfg['Servers'][\$i]['AllowDeny']['rules'] = array(\n&/" /usr/local/phpmyadmin/config.inc.php
		sed -i "66s/.*/		'deny % from all',\n&/" /usr/local/phpmyadmin/config.inc.php
		sed -i "67s/.*/		'allow % from localhost',\n&/" /usr/local/phpmyadmin/config.inc.php
		sed -i "68s/.*/		'allow % from 127.0.0.1',\n&/" /usr/local/phpmyadmin/config.inc.php
		sed -i "69s/.*/		'allow % from ::1',\n&/" /usr/local/phpmyadmin/config.inc.php
		sed -i "70s/.*/		'allow root from localhost',\n&/" /usr/local/phpmyadmin/config.inc.php
		sed -i "71s/.*/		'allow root from 127.0.0.1',\n&/" /usr/local/phpmyadmin/config.inc.php
		sed -i "72s/.*/		'allow root from ::1',\n&/" /usr/local/phpmyadmin/config.inc.php
		sed -i "73s/.*/);\n&/" /usr/local/phpmyadmin/config.inc.php
		sed -i "74s/.*/?>/" /usr/local/phpmyadmin/config.inc.php

		cat > /etc/nginx/sites-custom/phpmyadmin.conf <<END
location /pma {
	allow 127.0.0.1;
	deny all;
    auth_basic "Restricted";
    alias /usr/local/phpmyadmin;
    index index.php;

    location ~ ^/pma/(.+\.php)$ {
        alias /usr/local/phpmyadmin/\$1;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        include fastcgi_params;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME /usr/local/phpmyadmin/\$1;
        fastcgi_pass unix:/var/run/php5-fpm.sock;
    }

    location ~* ^/pma/(.+\.(jpg|jpeg|gif|css|png|js|ico|html|xml|txt))$ {
        alias /usr/local/phpmyadmin/\$1;
    }

    location ~ ^/pma/save/ {
        deny all;
    }

    location ~ ^/pma/upload/ {
        deny all;
    }
}
END

	else
		cat > /etc/nginx/sites-custom/phpmyadmin.conf <<END
location /pma {
    auth_basic "Restricted";
    alias /usr/local/phpmyadmin;
    index index.php;

    location ~ ^/pma/(.+\.php)$ {
        alias /usr/local/phpmyadmin/\$1;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        include fastcgi_params;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME /usr/local/phpmyadmin/\$1;
        fastcgi_pass unix:/var/run/php5-fpm.sock;
    }

    location ~* ^/pma/(.+\.(jpg|jpeg|gif|css|png|js|ico|html|xml|txt))$ {
        alias /usr/local/phpmyadmin/\$1;
    }

    location ~ ^/pma/save/ {
        deny all;
    }

    location ~ ^/pma/upload/ {
        deny all;
    }
}
END
	fi

	chown -R www-data:www-data phpmyadmin/	
	systemctl -q reload nginx.service

fi

# FIREWALL & SYSTEM TUNING
#
# Arno-Iptables-Firewall
# Fail2Ban
# System Tuning
#

#
# Arno-Iptable-Firewall
#

# Get the latest version
echo "${info} Installing Arno-Iptables-Firewall..." | awk '{ print strftime("[%H:%M:%S] |"), $0 }'
git clone https://github.com/arno-iptables-firewall/aif.git ~/sources/aif -q

# Create folders and copy files
cd ~/sources/aif
echo "${info} Configuring Arno-Iptables-Firewall..." | awk '{ print strftime("[%H:%M:%S] |"), $0 }'
mkdir -p /usr/local/share/arno-iptables-firewall/plugins
mkdir -p /usr/local/share/man/man1
mkdir -p /usr/local/share/man/man8
mkdir -p /usr/local/share/doc/arno-iptables-firewall
mkdir -p /etc/arno-iptables-firewall/plugins
mkdir -p /etc/arno-iptables-firewall/conf.d
cp bin/arno-iptables-firewall /usr/local/sbin/
cp bin/arno-fwfilter /usr/local/bin/
cp -R share/arno-iptables-firewall/* /usr/local/share/arno-iptables-firewall/
ln -s /usr/local/share/arno-iptables-firewall/plugins/traffic-accounting-show /usr/local/sbin/traffic-accounting-show
gzip -c share/man/man1/arno-fwfilter.1 >/usr/local/share/man/man1/arno-fwfilter.1.gz >/dev/null 2>&1
gzip -c share/man/man8/arno-iptables-firewall.8 >/usr/local/share/man/man8/arno-iptables-firewall.8.gz >/dev/null 2>&1
cp README /usr/local/share/doc/arno-iptables-firewall/
cp etc/init.d/arno-iptables-firewall /etc/init.d/
if [ -d "/usr/lib/systemd/system/" ]; then
  cp lib/systemd/system/arno-iptables-firewall.service /usr/lib/systemd/system/
fi
cp etc/arno-iptables-firewall/firewall.conf /etc/arno-iptables-firewall/
cp etc/arno-iptables-firewall/custom-rules /etc/arno-iptables-firewall/
cp -R etc/arno-iptables-firewall/plugins/ /etc/arno-iptables-firewall/
cp share/arno-iptables-firewall/environment /usr/local/share/

chmod +x /usr/local/sbin/arno-iptables-firewall
chown 0:0 /etc/arno-iptables-firewall/firewall.conf
chown 0:0 /etc/arno-iptables-firewall/custom-rules
chmod +x /usr/local/share/environment

# Start Arno-Iptables-Firewall at boot
update-rc.d -f arno-iptables-firewall start 11 S . stop 10 0 6 >/dev/null 2>&1

# Configure firewall.conf
bash /usr/local/share/environment >/dev/null 2>&1
sed -i "s/^Port 22/Port ${SSH}/g" /etc/ssh/sshd_config
sed -i "s/^EXT_IF=.*/EXT_IF="${INTERFACE}"/g" /etc/arno-iptables-firewall/firewall.conf
sed -i 's/^EXT_IF_DHCP_IP=.*/EXT_IF_DHCP_IP="0"/g' /etc/arno-iptables-firewall/firewall.conf
sed -i 's/^#FIREWALL_LOG=.*/FIREWALL_LOG="\/var\/log\/firewall.log"/g' /etc/arno-iptables-firewall/firewall.conf
sed -i 's/^DRDOS_PROTECT=.*/DRDOS_PROTECT="1"/g' /etc/arno-iptables-firewall/firewall.conf
sed -i 's/^OPEN_ICMP=.*/OPEN_ICMP="1"/g' /etc/arno-iptables-firewall/firewall.conf
sed -i 's/^#BLOCK_HOSTS_FILE=.*/BLOCK_HOSTS_FILE="\/etc\/arno-iptables-firewall\/blocked-hosts"/g' /etc/arno-iptables-firewall/firewall.conf
if [ ${USE_MAILSERVER} == '1' ]; then
	sed -i "s/^OPEN_TCP=.*/OPEN_TCP=\"${SSH}, 25, 80, 110, 143, 443, 465, 587, 993, 995\"/" /etc/arno-iptables-firewall/firewall.conf
else
	sed -i "s/^OPEN_TCP=.*/OPEN_TCP=\"${SSH}, 80, 443\"/" /etc/arno-iptables-firewall/firewall.conf
fi
sed -i 's/^OPEN_UDP=.*/OPEN_UDP=""/' /etc/arno-iptables-firewall/firewall.conf
sed -i 's/^VERBOSE=.*/VERBOSE=1/' /etc/init.d/arno-iptables-firewall

# Start the firewall
systemctl -q daemon-reload
systemctl -q start arno-iptables-firewall.service

#Fix error with /etc/rc.local
touch /etc/rc.local

# Blacklist some bad guys
mkdir ~/sources/blacklist
sed -i 's/.*BLOCK_HOSTS_FILE=.*/BLOCK_HOSTS_FILE="\/etc\/arno-iptables-firewall\/blocked-hosts"/' /etc/arno-iptables-firewall/firewall.conf
cat > /etc/cron.daily/blocked-hosts <<END
#!/bin/bash
BLACKLIST_DIR="/root/sources/blacklist"
BLACKLIST="/etc/arno-iptables-firewall/blocked-hosts"
BLACKLIST_TEMP="\$BLACKLIST_DIR/blacklist"

LIST=(
"http://www.projecthoneypot.org/list_of_ips.php?t=d&rss=1"
"http://check.torproject.org/cgi-bin/TorBulkExitList.py?ip=1.1.1.1"
"http://www.maxmind.com/en/anonymous_proxies"
"http://danger.rulez.sk/projects/bruteforceblocker/blist.php"
"http://rules.emergingthreats.net/blockrules/compromised-ips.txt"
"http://www.spamhaus.org/drop/drop.lasso"
"http://cinsscore.com/list/ci-badguys.txt"
"http://www.openbl.org/lists/base.txt"
"http://www.autoshun.org/files/shunlist.csv"
"http://lists.blocklist.de/lists/all.txt"
)

for i in "\${LIST[@]}"
do
    wget -T 10 -t 2 -O - \$i | grep -Po '(?:\d{1,3}\.){3}\d{1,3}(?:/\d{1,2})?' >> \$BLACKLIST_TEMP
done

sort \$BLACKLIST_TEMP -n | uniq > \$BLACKLIST
cp \$BLACKLIST_TEMP \${BLACKLIST_DIR}/blacklist\_\$(date '+%d.%m.%Y_%T' | tr -d :) && rm \$BLACKLIST_TEMP
systemctl force-reload arno-iptables-firewall.service
END
chmod +x /etc/cron.daily/blocked-hosts

# Fail2Ban
tar xf ~/sources/mailcow/fail2ban/inst/0.9.3.tar -C ~/sources/mailcow/fail2ban/inst/
rm -rf /etc/fail2ban/ >/dev/null 2>&1
(cd ~/sources/mailcow/fail2ban/inst/0.9.3 ; python setup.py -q install >/dev/null 2>&1)
mkdir -p /var/run/fail2ban
cp ~/sources/mailcow/fail2ban/conf/fail2ban.service /etc/systemd/system/fail2ban.service
[[ -f /lib/systemd/system/fail2ban.service ]] && rm /lib/systemd/system/fail2ban.service
systemctl -q daemon-reload
systemctl -q enable fail2ban
if [[ ! -f /var/log/mail.warn ]]; then
	touch /var/log/mail.warn
fi
if [[ ! -f /etc/fail2ban/jail.local ]]; then
	cp ~/sources/mailcow/fail2ban/conf/jail.local /etc/fail2ban/jail.local
fi
cp ~/sources/mailcow/fail2ban/conf/jail.d/*.conf /etc/fail2ban/jail.d/
rm -rf ~/sources/mailcow/fail2ban/inst/0.9.3
[[ -z $(grep fail2ban /etc/rc.local) ]] && sed -i '/^exit 0/i\test -d /var/run/fail2ban || install -m 755 -d /var/run/fail2ban/' /etc/rc.local
mkdir /var/run/fail2ban/ >/dev/null 2>&1

# System Tuning
echo "${info} Kernel hardening & system tuning..." | awk '{ print strftime("[%H:%M:%S] |"), $0 }'
cat > /etc/sysctl.conf <<END
kernel.randomize_va_space=1
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.all.accept_source_route=0
net.ipv4.icmp_echo_ignore_broadcasts=1
net.ipv4.conf.all.log_martians = 1
net.ipv4.tcp_fin_timeout = 1
net.ipv4.tcp_tw_recycle = 1
kernel.shmmax = 1073741824
net.ipv4.tcp_rmem = 4096 25165824 25165824
net.core.rmem_max = 25165824
net.core.rmem_default = 25165824
net.ipv4.tcp_wmem = 4096 65536 25165824
net.core.wmem_max = 25165824
net.core.wmem_default = 65536
net.core.optmem_max = 25165824
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_orphans = 262144
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2
net.core.default_qdisc=fq_codel
fs.inotify.max_user_instances=2048

# Disable IPV6
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
net.ipv6.conf.${INTERFACE}.disable_ipv6 = 1
END

# Enable changes
sysctl -p >/dev/null 2>&1


# Public Key Authentication
echo "${info} Generating key for public key authentication..." | awk '{ print strftime("[%H:%M:%S] |"), $0 }'
ssh-keygen -f ~/ssh.key -b 3072 -t rsa -N ${SSH_PASS} >/dev/null 2>&1
mkdir -p ~/.ssh && chmod 700 ~/.ssh
cat ~/ssh.key.pub > ~/.ssh/authorized_keys2 && rm ~/ssh.key.pub
chmod 600 ~/.ssh/authorized_keys2
mv ~/ssh.key ~/ssh_privatekey.txt

sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
sed -i 's/^UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config
echo -e "" >> /etc/ssh/sshd_config
echo -e "# Disable password based logins" >> /etc/ssh/sshd_config
echo -e "AuthenticationMethods publickey" >> /etc/ssh/sshd_config
systemctl -q restart ssh.service

truncate -s 0 /var/log/daemon.log
truncate -s 0 /var/log/syslog

# Restart all services
if [ ${USE_MAILSERVER} == '1' ]; then
	systemctl -q restart {fail2ban,rsyslog,nginx,php5-fpm,spamassassin,dovecot,postfix,opendkim,clamav-daemon,fuglu,mailgraph}
else
	systemctl -q restart {fail2ban,nginx,php5-fpm}
fi

}

addoninformation() {
touch ~/addoninformation.txt
echo "///////////////////////////////////////////////////////////////////////////" >> ~/addoninformation.txt
echo "// Passwords, Usernames, Databases" >> ~/addoninformation.txt
echo "///////////////////////////////////////////////////////////////////////////" >> ~/addoninformation.txt
echo "" >> ~/addoninformation.txt
echo "_______________________________________________________________________________________" >> ~/addoninformation.txt
}

source ~/userconfig.cfg
source ~/addonconfig.cfg
