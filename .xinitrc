[[ -f ~/.Xresources ]] && xrdb -merge ~/.Xresources
syndaemon -i 2 -K -t -R -d
# Now systemctl --user pulseaudio.service : pulseaudio --start
xautolock -locker 'i3lock -c 000000' &
#for i in $(xinput list | grep "Logitech USB Receiver" | perl -n -e'/id=(\d+)/ && print "$1\n"')
#	xinput set-button-map "$i" 1 1 3
#done
# xss-lock -- i3lock -c 000000 &
xset mouse 4 6

# Start a Polkit agent:
lxqt-policykit-agent & >/dev/null 2>&1

# xrandr --dpi 276
exec i3
