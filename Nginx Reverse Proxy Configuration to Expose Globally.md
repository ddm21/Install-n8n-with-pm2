## This configuration sets up two Nginx server blocks to route traffic to different backend services.
```nginx
server {
    server_name api.domain.tld;
    listen 80;

    location / {
        proxy_pass http://n8n.domain.tld/test$request_uri;
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
## Server Block 1: `api.domain.tld`

**Explanation:**

* **`server_name api.domain.tld;`**: Listens for requests to `api.domain.tld`.
* **`listen 80;`**: Listens on port 80 (standard HTTP).
* **`proxy_pass http://n8n.domain.tld/test$request_uri;`**: Sends requests to `n8n.domain.tld`, adding `/test` to the start of the requested path.
* **`proxy_set_header ...`**: Configures headers for proper forwarding, especially for WebSockets.
* **`proxy_buffering off;`**: Turns off buffering, useful for real-time applications.
* **`proxy_cache off;`**: Turns off caching.

**Simple Example:**

If you go to `api.domain.tld/mydata`, the server sends that request to `n8n.domain.tld/test/mydata`.

## Server Block 2: `n8n.domain.tld`

This block handles requests for `n8n.domain.tld`. It forwards these requests to a local application running on port 5678 (likely an n8n instance).

**Explanation:**

* **`server_name n8n.domain.tld;`**: Listens for requests to `n8n.domain.tld`.
* **`listen 80;`**: Listens on port 80.
* **`proxy_pass http://localhost:5678;`**: Sends requests to the application running on your server at port 5678.
* **`proxy_set_header ...`**: Configures headers for proper forwarding.
* **`proxy_buffering off;`**: Turns off buffering.
* **`proxy_cache off;`**: Turns off caching.

**Simple Example:**

When you go to `n8n.domain.tld`, the server sends your request to the application running locally on port 5678.

**Important Notes:**

* This configuration assumes your backend applications are running.
* It is highly recommended to use SSL/TLS (HTTPS) for security.
* The `proxy_buffering off;` and `proxy_cache off;` settings are often used for real-time applications or when you don't want to cache responses.
* The first server block prepends "/test" to the request path.
```
