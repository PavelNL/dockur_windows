#!/usr/bin/env bash
set -Eeuo pipefail

: "${SAMBA:="Y"}"

[[ "$SAMBA" != [Yy1]* ]] && return 0
[[ "$NETWORK" != [Yy1]* ]] && return 0

hostname="host.lan"
interface="dockerbridge"

if [[ "$DHCP" == [Yy1]* ]]; then
  hostname="$IP"
  interface="$VM_NET_DEV"
fi

share="$STORAGE/shared"

mkdir -p "$share"
[ -z "$(ls -A "$share")" ] && chmod -R 777 "$share"

{      echo "[global]"
        echo "    server string = Dockur"
        echo "    netbios name = $hostname"
        echo "    workgroup = WORKGROUP"
        echo "    interfaces = $interface"
        echo "    bind interfaces only = yes"
        echo "    security = user"
        echo "    guest account = nobody"
        echo "    map to guest = Bad User"
        echo "    server min protocol = NT1"
        echo ""
        echo "    # disable printing services"
        echo "    load printers = no"
        echo "    printing = bsd"
        echo "    printcap name = /dev/null"
        echo "    disable spoolss = yes"
        echo ""
        echo "[Data]"
        echo "    path = $share"
        echo "    comment = Shared"
        echo "    writable = yes"
        echo "    guest ok = yes"
        echo "    guest only = yes"
        echo "    force user = root"
        echo "    force group = root"
} > "/etc/samba/smb.conf"

{      echo "--------------------------------------------------------"
        echo " $APP for Docker v$(</run/version)..."
        echo " For support visit $SUPPORT"
        echo "--------------------------------------------------------"
        echo ""
        echo "Using this folder you can share files with the host machine."
        echo ""
        echo "To change the storage location, include the following bind mount in your compose file:"
        echo ""
        echo "  volumes:"
        echo "    - \"/home/user/example:/storage/shared\""
        echo ""
        echo "Or in your run command:"
        echo ""
        echo "  -v \"/home/user/example:/storage/shared\""
        echo ""
        echo "Replace the example path /home/user/example with the desired storage folder."
        echo ""
} | unix2dos > "$share/readme.txt"

! smbd && smbd --debug-stdout

isXP="N"

if [ -f "$STORAGE/windows.old" ]; then
  MT=$(<"$STORAGE/windows.old")
  [[ "${MT,,}" == "pc-q35-2"* ]] && isXP="Y"
fi

if [[ "$isXP" == [Yy1]* ]]; then
  [[ "$DHCP" == [Yy1]* ]] && return 0
  # Enable NetBIOS on Windows XP
  ! nmbd && nmbd --debug-stdout
else
  # Enable Web Service Discovery
  wsdd -i "$interface" -p -n "$hostname" &
fi

return 0
