FROM alpine:3.20.2

RUN mkdir -p /app /etc/frp

WORKDIR /app

COPY frps /usr/bin
COPY frpc /usr/bin

RUN chmod -R 777 /usr/bin/frps
RUN chmod -R 777 /usr/bin/frpc

COPY frp*ini /etc/frp/
COPY frp*toml /etc/frp/

#ENTRYPOINT ["/usr/bin/frps","-c","/app/frps.ini"]
