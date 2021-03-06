#! /bin/bash
set -e

socket=${XDG_RUNTIME_DIR}/egmde_socket
wayland_display=egmde_wayland
bindir=$(dirname $0)
vt=4

while [ $# -gt 0 ]
do
  if [ "$1" == "--help" -o "$1" == "-h" ]
  then
    echo "$(basename $0) - Handy launch script for a egmde \"desktop session\""
    echo "Usage: $(basename $0) [options] [shell options]"
    echo "Options are:"
    echo "    --vt <termid>                 set the virtual terminal [${vt}]"
    exit 0
  elif [ "$1" == "--vt" ];                then shift; vt=$1
  else break
  fi
  shift
done

if [ "${bindir}" != "" ]; then bindir="${bindir}/"; fi

if [ -e "${socket}" ]; then echo "Error: session endpoint '${socket}' already exists"; exit 1 ;fi
if [ -e "${XDG_RUNTIME_DIR}/${wayland_display}" ]; then echo "Error: wayland endpoint '${wayland_display}' already exists"; exit 1 ;fi
if [ ! -d "${XDG_RUNTIME_DIR}" ]; then echo "Error: XDG_RUNTIME_DIR '${XDG_RUNTIME_DIR}' does not exists"; exit 1 ;fi

vt_login_session=$(who -u | grep tty${vt} | grep ${USER} | wc -l)
if [ "${vt_login_session}" == "0" ]; then echo "Error: please log into tty${vt} first"; exit 1 ;fi

keymap_index=$(gsettings get org.gnome.desktop.input-sources current | cut -d\  -f 2)
keymap=$(gsettings get org.gnome.desktop.input-sources sources | grep -Po "'[[:alpha:]]+'\)" | sed -ne "s/['|)]//g;$(($keymap_index+1))p")

oldvt=$(sudo fgconsole)
sudo --preserve-env sh -c "chvt ${vt}; su -c '${bindir}egmde --wayland-socket-name ${wayland_display} --arw-file --file ${socket} --keymap ${keymap} $*' ${USER};\
    sleep 1; chvt ${oldvt}"
