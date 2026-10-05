#!/usr/bin/env bash
set -Eeuo pipefail

mkdir -p /tmp/nanolimbo-test-bin
cat > /tmp/nanolimbo-test-bin/curl <<'CURL'
#!/usr/bin/env bash
set -Eeuo pipefail
case "${TEST_DOWNLOAD_MODE:-valid}" in
  failed)
    printf 'partial download\n' > .settings.yml.download
    exit 22
    ;;
  invalid)
    printf 'unsupported: settings\n' > .settings.yml.download
    ;;
  valid)
    printf 'server:\n  ip: "localhost"\n  port: 65535\n' > .settings.yml.download
    ;;
esac
CURL
chmod 0755 /tmp/nanolimbo-test-bin/curl
cat > /usr/local/bin/kiln-ember <<'EMBER'
#!/usr/bin/env bash
set -Eeuo pipefail
printf 'launched\n' > /server/launcher-called
EMBER
chmod 0755 /usr/local/bin/kiln-ember

export PATH="/tmp/nanolimbo-test-bin:${PATH}"
export KILN_NANOLIMBO_SETTINGS_URL=https://example.invalid/settings.yml
export KILN_INSTALLATION_MARKER=.kiln-ember-installed
cd /server

/usr/local/bin/kiln-nanolimbo
grep -qF 'ip: "0.0.0.0"' settings.yml
grep -qF 'port: 25565' settings.yml
test -f launcher-called
test ! -e .settings.yml.download
echo 'PASS: first start configures NanoLimbo and delegates to upstream'

printf 'custom: settings\n' > settings.yml
rm launcher-called
TEST_DOWNLOAD_MODE=failed /usr/local/bin/kiln-nanolimbo
test "$(cat settings.yml)" = 'custom: settings'
test -f launcher-called
echo 'PASS: existing settings are preserved without downloading'

rm settings.yml launcher-called
touch .kiln-ember-installed
status=0
TEST_DOWNLOAD_MODE=failed /usr/local/bin/kiln-nanolimbo || status=$?
test "${status}" -eq 22
test ! -e settings.yml
test ! -e .settings.yml.download
test ! -e launcher-called
test ! -e .kiln-ember-installed
echo 'PASS: download failure clears partial files and the installation marker'

status=0
TEST_DOWNLOAD_MODE=invalid /usr/local/bin/kiln-nanolimbo || status=$?
test "${status}" -eq 65
test ! -e settings.yml
test ! -e .settings.yml.download
test ! -e launcher-called
echo 'PASS: unexpected settings fail before launching NanoLimbo'

printf 'preserve\n' > marker-target
status=0
KILN_INSTALLATION_MARKER=marker-target /usr/local/bin/kiln-nanolimbo || status=$?
test "${status}" -eq 64
test "$(cat marker-target)" = preserve
test ! -e launcher-called
echo 'PASS: invalid installation markers cannot delete arbitrary files'
