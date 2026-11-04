# env.nu
#
# Installed by:
# version = "0.116.1"
#
# Previously, environment variables were typically configured in `env.nu`.
# In general, most configuration can and should be performed in `config.nu`
# or one of the autoload directories.
#
# This file is generated for backwards compatibility for now.
# It is loaded before config.nu and login.nu
#
# See https://www.nushell.sh/book/configuration.html
#
# Also see `help config env` for more options.
#
# You can remove these comments if you want or leave
# them for future reference.

$env.IN_USE_SHELL = "Nushell"
$env.PATH = ($env.PATH | prepend $"($env.HOME)/.cargo/bin")
$env.PATH = ($env.PATH | prepend $"($env.HOME)/.bun/bin")
$env.PATH = ($env.PATH | prepend $"($env.HOME)/go/bin")
$env.PATH = ($env.PATH | append $"$($env.HOME)/Library/Application Support/JetBrains/Toolbox/scripts")

# Homebrew：对应 brew shellenv 的环境配置，使用 Nushell 原生语法。
$env.HOMEBREW_PREFIX = "/opt/homebrew"
$env.HOMEBREW_CELLAR = $"($env.HOMEBREW_PREFIX)/Cellar"
$env.HOMEBREW_REPOSITORY = $env.HOMEBREW_PREFIX
$env.PATH = (
    $env.PATH
    | prepend [$"($env.HOMEBREW_PREFIX)/bin" $"($env.HOMEBREW_PREFIX)/sbin"]
    | uniq
)

# MANPATH 未设置时保留系统默认；已设置时用前导冒号包含默认搜索路径。
if ($env.MANPATH? | default "" | is-not-empty) {
    $env.MANPATH = $":($env.MANPATH | str trim --char ':')"
}

# 保留 INFOPATH 中的自定义目录和空项（代表默认搜索路径）。
$env.INFOPATH = (
    [$"($env.HOMEBREW_PREFIX)/share/info"]
    | append ($env.INFOPATH? | default "" | split row (char esep))
    | uniq
    | str join (char esep)
)

$env.STARSHIP_CONFIG = $"($env.HOME)/.config/starship/starship.toml"
$env.HF_ENDPOINT = "https://hf-mirror.com"

fnm env --shell power-shell | fnm-nushell | from json | reject PATH | load-env
$env.PATH = ($env.PATH | append $"$($env.FNM_MULTISHELL_PATH)/bin")
