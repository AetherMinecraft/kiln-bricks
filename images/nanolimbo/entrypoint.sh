#!/usr/bin/env bash
set -Eeuo pipefail

cd /server

installation_marker="${KILN_INSTALLATION_MARKER:-}"
if [[ -n "${installation_marker}" && ! "${installation_marker}" =~ ^\.kiln-[a-zA-Z0-9._-]{1,58}$ ]]; then
  echo "[NanoLimbo] KILN_INSTALLATION_MARKER must be a reserved .kiln-* filename" >&2
  exit 64
fi
if [[ -n "${installation_marker}" ]]; then
  rm -f -- "${installation_marker}"
fi

if [[ ! -e settings.yml ]]; then
  : "${KILN_NANOLIMBO_SETTINGS_URL:?KILN_NANOLIMBO_SETTINGS_URL is required}"
  echo "[NanoLimbo] downloading settings"
  if curl --fail --location --no-progress-meter --retry 2 --retry-all-errors \
    --connect-timeout 15 --max-time 300 \
    --output .settings.yml.download "${KILN_NANOLIMBO_SETTINGS_URL}"; then
    sed -i \
      -e 's/ip: "localhost"/ip: "0.0.0.0"/' \
      -e 's/port: 65535/port: 25565/' \
      .settings.yml.download
    if ! grep -qF 'ip: "0.0.0.0"' .settings.yml.download || \
      ! grep -qF 'port: 25565' .settings.yml.download; then
      rm -f -- .settings.yml.download
      echo "[NanoLimbo] settings do not contain the expected bind configuration" >&2
      exit 65
    fi
    mv -- .settings.yml.download settings.yml
  else
    status=$?
    rm -f -- .settings.yml.download
    echo "[NanoLimbo] failed to download settings after 3 attempts" >&2
    exit "${status}"
  fi
fi

exec /usr/local/bin/kiln-ember "$@"
