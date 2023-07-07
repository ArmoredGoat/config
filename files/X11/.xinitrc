# Autostart programs

# Check if there is already a cached color scheme and if yes, reload it.
# Otherwise run pywal and create a color scheme.
if [[ -d ~/.cache/wal ]]; then
    wal -R -n &
else
    wal -n -i ~/.local/share/backgrounds/hollow_knight_lantern.png &
fi

# Start compositor
picom &
# Restore set wallpaper
nitrogen --restore &

# Start Qtile
exec dbus-launch --exit-with-session qtile start