FROM ghcr.io/kiln-site/bricks-java:21

COPY --chmod=0755 images/nanolimbo/entrypoint.sh /usr/local/bin/kiln-nanolimbo

LABEL org.opencontainers.image.source="https://github.com/AetherMinecraft/kiln-bricks"
LABEL org.opencontainers.image.title="AetherMinecraft NanoLimbo Ember"
LABEL org.opencontainers.image.licenses="AGPL-3.0-only"

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/kiln-nanolimbo"]
