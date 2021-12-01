# On directory change, add the new directory to fre's cache
function __fre_on_variable_pwd -v PWD
    if type -q fre
        command fre --add "$PWD"
     end
end
