# alpine-proot

Run Alpine Linux desktop (IceWM) via PRoot with VNC + noVNC web access.

## Usage

```bash
bash alpine.sh
```

## What it does

1. Downloads PRoot + latest Alpine mini rootfs
2. Installs: IceWM, TigerVNC, Xvfb, xfce4-terminal, noVNC, websockify
3. Starts Xvnc + websockify + IceWM session
4. Access via noVNC web client (port 6081)

##
Recommend using with pterodactyl server env like SERVER_PORT,HOSTNAME already set

## Defaults

| Item | Value |
|---|---|
| VNC password | `$HOSTNAME` (or `123456`) |
| Web port | `$SERVER_PORT` (or `6081`) |
| Install path | `$HOME/alpine` |
| Display | `:1` |
| Resolution | 1280x720 depth 16 |

## Env vars

```bash
SERVER_PORT=9090 HOSTNAME=mysecret bash alpine.sh
```

## Requirements

- PRoot support (Pterodactyl server, any Linux with proot)
- ~300MB free space
- Internet connection (first run only)
