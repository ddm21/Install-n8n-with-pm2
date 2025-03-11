## This configuration sets up two Nginx server blocks to route traffic to different backend services.
```nginx
server {
    server_name api.domain.tld;
    listen 80;

    location /test/ {
        proxy_pass http://n8n.domain.tld$request_uri;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
        proxy_http_version 1.1;
        chunked_transfer_encoding off;
        proxy_buffering off;
        proxy_cache off;
    }

    location /prod/ {
        proxy_pass http://n8n.domain.tld$request_uri;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
        proxy_http_version 1.1;
        chunked_transfer_encoding off;
        proxy_buffering off;
        proxy_cache off;
    }
}

server {
    server_name n8n.domain.tld;
    listen 80;

    location / {
        proxy_pass http://localhost:5678;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
        proxy_http_version 1.1;
        chunked_transfer_encoding off;
        proxy_buffering off;
        proxy_cache off;
    }
}
```

## Explanation:

- Requests to **`api.domain.tld/test/{route}`** → Redirect to **`n8n.domain.tld/test/{route}`**  
- Requests to **`api.domain.tld/prod/{route}`** → Redirect to **`n8n.domain.tld/prod/{route}`**  

**Important Notes:**

* This configuration assumes your backend applications are running.
* It is highly recommended to use SSL/TLS (HTTPS) for security.
* The `proxy_buffering off;` and `proxy_cache off;` settings are often used for real-time applications or when you don't want to cache responses.
* The first server block prepends "/test" to the request path.
