# nginx config serving Django site on `https://example.com`
server {
        listen 80;
	listen [::]:80;

        server_name example.com;

	root /var/www/example.com/htdocs;

	index index.html;

	location /.well-known/acme-challenge/ {
		# Note: we use root since certbot wants to place files in
		# $DIR/.well-known/acme-challenge/
		root /var/www/acme-challenge/example.com/;
	}

	rewrite ^/.well-known/acme-challenge/ $request_uri last;
	rewrite ^ https://example.com$request_uri?;
}

server {
	listen 443 ssl;
	listen [::]:443 ssl;
	ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
	ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

	server_name example.com;

	root /var/www/example.com/htdocs;

	index index.html;

        location / {
                proxy_pass http://127.0.0.1:14723;
        }
        location /static {
                alias /var/www/example.com/static;
        }

	location /.well-known/acme-challenge/ {
		# Not strictly needed, but it is nice to serve the same files
		# on HTTP and HTTPS.
		root /var/www/acme-challenge/example.com/;
	}
}
