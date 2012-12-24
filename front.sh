echo "###############################################"
echo "# installing front                            #"
echo "###############################################"

wget http://nginx.org/packages/keys/nginx_signing.key

cat nginx_signing.key | sudo apt-key add -

cat > /etc/apt/sources.list.d/nginx.list << EOF
deb http://nginx.org/packages/ubuntu/ precise nginx
deb-src http://nginx.org/packages/ubuntu/ precise nginx
EOF

apt-get update

apt-get install -y vim nginx

mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.bak
mv /etc/nginx/conf.d/example_ssl.conf /etc/nginx/conf.d/example_ssl.conf.bak

mkdir /etc/nginx/include.d

cat > /etc/nginx/include.d/proxy-common.conf << EOF
proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
proxy_redirect off;
proxy_buffering off;
proxy_set_header        Host            \$host;
proxy_set_header        X-Real-IP       \$remote_addr;
proxy_set_header        X-Forwarded-For \$proxy_add_x_forwarded_for;
EOF

cat > /etc/nginx/conf.d/stacksherpa.conf << EOF
upstream keystone  {
      server 10.20.30.50:35357; #keystone-admin
}

server {
	listen 80;
	server_name keystone.stacksherpa.com
	
	location / {
		proxy_pass  http://keystone;
		include /etc/nginx/include.d/proxy-common.conf;
	}
}

upstream identity  {
      server 10.20.30.50:5000; #keystone-public
}

server {
	listen 80;
	server_name identity.stacksherpa.com
	
	location / {
		proxy_pass  http://identity;
		include /etc/nginx/include.d/proxy-common.conf;
	}
}

upstream compute  {
      server 10.20.30.50:8774; #nova
}

server {
	listen 80;
	server_name compute.stacksherpa.com
	
	location / {
		proxy_pass  http://compute;
		include /etc/nginx/include.d/proxy-common.conf;
	}
}

upstream images  {
      server 10.20.30.50:9292; #glance
}

server {
	listen 80;
	server_name images.stacksherpa.com
	
	location / {
		proxy_pass  http://images;
		include /etc/nginx/include.d/proxy-common.conf;
	}
}

upstream metering  {
      server 10.20.30.60:8777; #horizon
}

server {
	listen 80;
	server_name metering.stacksherpa.com
	
	location / {
		proxy_pass  http://metering;
		include /etc/nginx/include.d/proxy-common.conf;
	}
}

upstream dashboard  {
      server 10.20.30.50:80; #horizon
}

server {
	listen 80;
	server_name dashboard.stacksherpa.com
	
	location / {
		proxy_pass  http://dashboard;
		include /etc/nginx/include.d/proxy-common.conf;
	}
}
EOF

service nginx restart