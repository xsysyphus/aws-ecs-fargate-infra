# Use uma imagem base oficial do Nginx
FROM nginx:1.21.6-alpine

# Remova a configuração padrão
RUN rm /etc/nginx/conf.d/default.conf

# Copie a configuração customizada do Nginx
COPY nginx.conf /etc/nginx/nginx.conf

# Copie os certificados do servidor e da CA
# O Dockerfile deve estar no mesmo nível que o diretório 'certs'
COPY ./certs/server.fullchain.crt /etc/nginx/certs/server.fullchain.crt
COPY ./certs/server.key /etc/nginx/certs/server.key
COPY ./certs/ca.crt /etc/nginx/certs/ca.crt

# Exponha a porta 443
EXPOSE 443
