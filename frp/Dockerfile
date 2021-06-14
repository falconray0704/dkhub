FROM alpine:3.12.0

RUN mkdir -p /app

WORKDIR /app

COPY frps /usr/bin
COPY frpc /usr/bin

RUN chmod -R 777 /usr/bin/frps
RUN chmod -R 777 /usr/bin/frpc

COPY frp*ini /app/

#ENTRYPOINT ["/usr/bin/frps","-c","/app/frps.ini"]
