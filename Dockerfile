FROM golang:1.18-bullseye as builder

ARG VER=devel

ENV CGO_ENABLED=0

RUN mkdir -p /cache/crypto
COPY crypto /cache/crypto
COPY go.mod go.sum /cache/
WORKDIR /cache
RUN go mod download

RUN mkdir -p /out/plugins
ADD . /src/
WORKDIR /src
RUN --mount=type=cache,target=/root/.cache/go-build go build -o /out -ldflags "-X main.mainver=$VER" ./cmd/...
RUN --mount=type=cache,target=/root/.cache/go-build go build -o /out/plugins  -ldflags "-X main.mainver=$VER" ./plugin/...

FROM busybox
LABEL maintainer="Boshi Lian<farmer1992@gmail.com>"

COPY --from=ep76/openssh-static:latest /usr/bin/ssh-keygen /bin/ssh-keygen
RUN mkdir /etc/ssh/
RUN mkdir /sshpiperd

ADD entrypoint.sh /sshpiperd
COPY --from=builder /out/ /sshpiperd
EXPOSE 2222

ENTRYPOINT ["/sshpiperd/entrypoint.sh"]
CMD ["/sshpiperd/sshpiperd", "/sshpiperd/plugins/workingdir"]
