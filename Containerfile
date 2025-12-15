FROM docker.io/cuelang/cue:0.15.1

LABEL org.opencontainers.image.source=https://github.com/deepbrook/argocd-cmp-cuelang

ENV CUE_CACHE_DIR /opt/var/cue
WORKDIR /opt/var/cue
WORKDIR /home/argocd/cmp-server/config/
COPY plugin.yaml ./
ENTRYPOINT ["/usr/bin/cue"]
