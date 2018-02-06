# nginx config redirecting `https://redirect.example.com` to `https://example.com`
server {
	listen 80;
	listen [::]:80;

	server_name redirect.example.com;

	root /var/www/redirect.example.com/htdocs;

	index index.html;

	location /.well-known/acme-challenge/ {
		# Note: we use root since certbot wants to place files in
		# $DIR/.well-known/acme-challenge/
		root /var/www/acme-challenge/redirect.example.com/;
	}

	rewrite ^/.well-known/acme-challenge/ $request_uri last;
	# First, redirect to https on same domain
	rewrite ^ https://redirect.example.com$request_uri?;
}
server {
	listen 443 default_server ssl;
	listen [::]:443 ssl;
	ssl_certificate /etc/letsencrypt/live/redirect.example.com/fullchain.pem;
	ssl_certificate_key /etc/letsencrypt/live/redirect.example.com/privkey.pem;

	server_name redirect.example.com;

	root /var/www/redirect.example.com/htdocs;

	index index.html;

	location /.well-known/acme-challenge/ {
		root /var/www/acme-challenge/redirect.example.com/;
	}

	rewrite ^/.well-known/acme-challenge/ $request_uri last;
	# On https, redirect to target domain
	rewrite ^ https://example.com$request_uri?;
}
