if status is-interactive
    fastfetch
end

set -g fish_greeting
set -gx PATH $PATH /home/qua.cn/.dotnet/tools

set -x DOTNET_CLI_TELEMETRY_OPTOUT 1
set -x LC_ALL C.UTF-8
