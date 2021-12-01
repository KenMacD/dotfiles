function z-cleanup
    fre --sorted | while read -l dir; if [ ! -d "$dir" ]; fre --delete "$dir"; end; end
end
