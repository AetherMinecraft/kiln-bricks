# AetherMinecraft Kiln Bricks

Custom server recipes and runtimes that work with unmodified Kiln.

In Kiln's Brick catalog manager, add `AetherMinecraft/kiln-bricks`. This adds
NanoLimbo alongside the official catalog. Publish the imported catalog in Kiln
if other accounts should be able to use it. Catalog imports are snapshots;
import a new snapshot when updating recipes.

The NanoLimbo recipe uses
`ghcr.io/aetherminecraft/kiln-bricks/nanolimbo:java21`. The image extends
upstream's Java 21 Ember, downloads release-matched settings on the first start,
and configures the listener at `0.0.0.0:25565`. Existing `settings.yml` files are
preserved. Jar downloads and Java startup remain handled by upstream's launcher.

Existing NanoLimbo servers keep their selected runtime image until their Startup
configuration is changed to this recipe/image. Their mounted server data remains
in place.

GitHub Actions validates the catalog, tests settings initialization, and publishes
amd64/arm64 images on pushes to `main`. A monthly rebuild picks up upstream Java
runtime updates. The GHCR package must be public so Relays can pull it.

```sh
pnpm install --frozen-lockfile
pnpm test
docker build -f images/nanolimbo/Dockerfile -t nanolimbo:test .
docker run --rm --entrypoint bash \
  --mount "type=bind,source=$PWD/tests,target=/tests,readonly" \
  nanolimbo:test /tests/nanolimbo.sh
```

Validation uses Kiln's v1 schemas pinned to upstream commit `b4c2cf7` and requires
network access. Source is licensed under AGPL-3.0; see `LICENSE` and `NOTICE`.
