ARG CUE_VERSION
FROM docker.io/cuelang/cue:$CUE_VERSION

LABEL org.opencontainers.image.source=https://github.com/deepbrook/argocd-cmp-cuelang

ENV CUE_CACHE_DIR /opt/cue
USER 999
WORKDIR /opt/cue
WORKDIR /home/argocd/cmp-server/config/
COPY plugin.yaml ./
ENTRYPOINT ["/usr/bin/cue"]
