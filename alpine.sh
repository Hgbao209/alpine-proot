#!/bin/bash
set -e

INSTALL_PATH="$HOME/alpine"
ARCH=$(uname -m)
VNC_PASS="${HOSTNAME:-123456}"
WEBSOCKET_PORT="${SERVER_PORT:-6081}"
BASE_URL="https://dl-cdn.alpinelinux.org/latest-stable/releases/$ARCH"

mkdir -p "$INSTALL_PATH" && cd "$INSTALL_PATH"

if [ ! -f proot ]; then
    curl -sL "https://github.com/proot-me/proot/releases/download/v5.3.0/proot-v5.3.0-$ARCH-static" -o proot
    chmod +x proot

    LATEST_TARBALL=$(curl -sL "$BASE_URL/latest-releases.yaml" | \
        sed -n '/title: "Mini root filesystem"/,/^-/p' | \
        grep "file:" | head -n 1 | awk -F': ' '{print $2}' | tr -d '" ')

    if [ -z "$LATEST_TARBALL" ]; then
        exit 1
    fi

    DOWNLOAD_URL="$BASE_URL/$LATEST_TARBALL"

    for i in 1 2 3; do
        if curl -sL "$DOWNLOAD_URL" -o rootfs.tar.gz && [ -s rootfs.tar.gz ]; then
            tar -xf rootfs.tar.gz && rm rootfs.tar.gz
            break
        fi
        sleep 2
    done
fi

if [ ! -f .setup_done ]; then
    cp /etc/resolv.conf etc/
    mkdir -p tmp/.X11-unix
    chmod 1777 tmp/.X11-unix
    
    PROOT_NO_SECCOMP=1 ./proot -r . -w / -0 -b /dev -b /proc -b /sys -b /tmp /bin/sh -c "
        apk update --no-cache || true
        apk add --no-cache bash icewm tigervnc xorg-server xvfb \
            xfce4-terminal xkeyboard-config xauth ttf-dejavu \
            python3 py3-pip git curl
        mkdir -p \$HOME/.vnc
        echo '$VNC_PASS' | vncpasswd -f > \$HOME/.vnc/passwd
        chmod 600 \$HOME/.vnc/passwd
        echo 'exec icewm-session' > \$HOME/.xinitrc
        
        pip3 install --break-system-packages websockify
        
        cd /tmp
        git clone --depth 1 https://github.com/novnc/noVNC.git
        mkdir -p /usr/local/share/novnc
        cp -r /tmp/noVNC/* /usr/local/share/novnc/
        rm -rf /tmp/noVNC
    "
    touch .setup_done
fi

PROOT_NO_SECCOMP=1 ./proot -r . -w / -0 -b /dev -b /proc -b /sys -b /tmp /bin/sh -c "
    export DISPLAY=:1
    
    Xvnc :1 -rfbauth \$HOME/.vnc/passwd -geometry 1280x720 -depth 16 \
    -rfbport 5900 -localhost yes -AlwaysShared -xkbdir /usr/share/X11/xkb &
    
    sleep 3
    
    websockify --web /usr/local/share/novnc --cert=none 0.0.0.0:$WEBSOCKET_PORT localhost:5900 &
    
    icewm-session &
    tail -f /dev/null
"

echo "=========================================="
echo "noVNC đã start"
echo "Truy cập: $WEBSOCKET_PORT/vnc.html"
echo "Mật khẩu VNC: $VNC_PASS"
echo "=========================================="