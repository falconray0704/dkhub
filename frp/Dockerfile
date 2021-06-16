FROM alpine:3.12.0

RUN mkdir -p /app /etc/frp

WORKDIR /app

COPY frps /usr/bin
COPY frpc /usr/bin

RUN chmod -R 777 /usr/bin/frps
RUN chmod -R 777 /usr/bin/frpc

COPY frp*ini /etc/frp/

#ENTRYPOINT ["/usr/bin/frps","-c","/app/frps.ini"]
