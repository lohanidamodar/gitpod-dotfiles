if not set -q OLLAMA_HOST
    if test -e /proc/sys/fs/binfmt_misc/WSLInterop; or set -q WSL_DISTRO_NAME
        set -l _gw (ip route show default 2>/dev/null | awk '/default/ {print $3; exit}')
        if test -n "$_gw"
            set -gx OLLAMA_HOST "http://$_gw:11434"
        end
    end
end
