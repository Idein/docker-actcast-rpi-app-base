#!/usr/bin/env bash
set -x
exec 1>&2

# キーボードを抜き差ししても設定した配列で認識されるようにする
# アプリの実装で KEYLAYOUT, KEYMODEL を上書きできるようにここで動的に設定ファイルを作る
cat <<CFG > /etc/X11/xorg.conf.d/00-keyboard.conf
Section "InputClass"
    Identifier "system-keyboard"
    MatchIsKeyboard "on"
    Option "XkbLayout" "${KEYLAYOUT}"
    Option "XkbModel"  "${KEYMODEL}"
EndSection
CFG

DISPLAY="${DISPLAY:-:0}"
VT="${VT:-7}"

mkdir -p /var/log

/etc/init.d/dbus start

# Xorg起動（VTを掴んでKMSへ出す）
# -keeptty: VT保持、-nolisten tcp: TCP無効、-noreset: クライアント終了で落ちない
Xorg "${DISPLAY}" "vt${VT}" -keeptty -nolisten tcp -noreset \
  -logfile /var/log/Xorg.0.log &
XORG_PID=$!

cleanup() {
  # debug
  echo "Xorg: log in cleanup"
  cat /var/log/Xorg.0.log
  echo "Xorg: log- in cleanup"

  kill "${XORG_PID}" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# 起動待ち
for _ in $(seq 1 10); do
  xdpyinfo -display "${DISPLAY}" >/dev/null 2>&1 && break
  sleep 0.5
done
xdpyinfo -display "${DISPLAY}" >/dev/null 2>&1 || { echo "ERROR: Xorg did not start"; exit 1; }

# ディスプレイのスリープ防止
xset s off
xset s noblank
xset -dpms

echo "Xorg: log"
cat /var/log/Xorg.0.log
echo "Xorg: log-"

uid=$(id -u "idein")
gid=$(id -g "idein")

chown -R idein:idein /home/idein
export HOME=/home/idein

# rootユーザーだと mozc_server が動作しないため通常ユーザーで実行する
exec setpriv --reuid="$uid" --regid="$gid" --init-groups \
  dbus-run-session -- bash -lc '
    set -e

    XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/xdg-${UID}}"
    export XDG_RUNTIME_DIR
    mkdir -p "${XDG_RUNTIME_DIR}"
    chmod 700 "${XDG_RUNTIME_DIR}"

    fcitx5 -d --replace

    openbox &
    exec "$@"
  ' -- "$@"
