# config.nu
#
# Installed by:
# version = "0.116.1"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# Nushell sets "sensible defaults" for most configuration settings, 
# so your `config.nu` only needs to override these defaults if desired.
#
# You can open this file in your default editor using:
#     config nu
#
# You can also pretty-print and page through the documentation for configuration
# options using:
#     config nu --doc | nu-highlight | less -R

# 默认编辑器：neovim
$env.config.buffer_editor = "nvim"
$env.EDITOR = "nvim"
$env.VISUAL = "nvim"

# 启动不显示 banner
$env.config.show_banner = false

# Kubernetes：每次显式指定 context，避免依赖 current-context。
alias cuk = ^kubectl --context cu-k8s
alias lok = ^kubectl --context local-k3s

# 查询资源并把 JSON 解析成 Nu 数据，例如：kcuj pods -A | get items
def --wrapped cukj [...args: string] {
    ^kubectl --context cu-k8s ...$args -o json | from json
}

def --wrapped lokj [...args: string] {
    ^kubectl --context local-k3s ...$args -o json | from json
}

# 列出本机 TCP LISTEN 端口，并 left join Nushell 内置 ps -l 的进程信息。
# 用法：
#   lsof_tcp_listen
#   lsof_tcp_listen | where port == 5000
#   lsof_tcp_listen | where ps_command == null
def lsof_tcp_listen [] {
    let lsof_table = (
        ^lsof -nP -iTCP -sTCP:LISTEN -Fpcn
        | into string
        | lines
        | parse --regex '^(?P<k>[a-z])(?P<v>.*)$'
        | reduce --fold {proc: {}, fd: "", rows: []} {|it, acc|
            match $it.k {
                'p' => {proc: {pid: ($it.v | into int), command: ""}, fd: "", rows: $acc.rows}
                'c' => {proc: ($acc.proc | merge {command: $it.v}), fd: $acc.fd, rows: $acc.rows}
                'f' => {proc: $acc.proc, fd: $it.v, rows: $acc.rows}
                'n' => {proc: $acc.proc, fd: $acc.fd, rows: ($acc.rows | append ($acc.proc | merge {fd: $acc.fd, name: $it.v}))}
                _   => $acc
            }
        }
        | get rows
        | insert port {|r| $r.name | str replace --regex '.*:' '' | into int }
        | select command pid fd port name
        | sort-by port
    )

    let ps_table = (
        ps -l
        | select pid name command
        | update command { str trim }
    )

    $lsof_table
    | join --left --prefix ps_ $ps_table pid
    | select pid ps_name port name ps_command
}

def ntom [] {
  ($in | str replace 'n' '' | into int) / 1000000
  | math floor
}

def kitomi [] {
  ($in | str replace 'Ki' '' | into int) / 1024
  | math floor
}

def nodes_usage [cluster: string, nodes: list<string>] {
  let all_nodes = ^kubectl --context $cluster get --raw /apis/metrics.k8s.io/v1beta1/nodes
  | from json
  | get items
  | select metadata.name usage.cpu usage.memory
  | rename name cpu memory

  $all_nodes | where $in.name in $nodes
  | each { |n| {name: $n.name cpu: ($n.cpu | ntom) memory: ($n.memory | kitomi) } }
}


def pods_usage [cluster: string] {
  ^kubectl --context $cluster get --raw /apis/metrics.k8s.io/v1beta1/pods
  | from json
  | get items
  | select metadata.namespace metadata.name containers
  | rename namespace name containers
  | where namespace not-in ['kube-system' 'monitoring']
  | each {|l|
      $l.containers
      | each {|c|
          {
            namespace: $l.namespace
            name: $l.name
            cpu: ($c.usage.cpu | ntom)
            memory: ($c.usage.memory | kitomi)
          }
        }
    }
  | flatten
}
