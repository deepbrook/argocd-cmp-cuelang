ARG CUE_VERSION
FROM docker.io/cuelang/cue:$CUE_VERSION as CUE_BINARY
FROM docker.io/python:3-alpine
LABEL org.opencontainers.image.source=https://github.com/deepbrook/argocd-cmp-cuelang

USER 999
COPY --from=CUE_BINARY /usr/bin/cue /usr/bin/cue
COPY src/cue-cmp /usr/bin/cue-cmp
WORKDIR /opt/cue
ENV CUE_CACHE_DIR /opt/cue
WORKDIR /home/argocd/cmp-server/config/
COPY plugin.yaml ./
ENTRYPOINT ["/usr/bin/cue-cmp"]
