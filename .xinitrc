[[ -f ~/.Xresources ]] && xrdb -merge ~/.Xresources
syndaemon -i 2 -K -t -R -d
pulseaudio --start
xss-lock -- i3lock -c 000000 &
exec i3
