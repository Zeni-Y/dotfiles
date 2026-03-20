# 補完を使おうとした時に初めて補完関数を読み込む
# コマンドが存在しない場合は何もしない
#
# usage: on_demand_completion <command_name> [completion_command]
#   command_name:       補完を行うコマンド名
#   completion_command: 補完スクリプトを標準出力に出力するコマンド
#                       (default: "<command_name> completion zsh")
#
# Example:
#   on_demand_completion 'docker'
#   on_demand_completion 'gh' 'gh completion -s zsh'
on_demand_completion() {
  local cmd_name=$1
  local completion_command="${2:-${cmd_name} completion zsh}"
  local function_name="_${cmd_name}"

  # コマンドが存在するかチェック
  if ! command -v "$cmd_name" &>/dev/null; then
    return
  fi

  # Tab キーが押された時に初めて補完スクリプトを評価するスタブ関数を登録
  eval "function ${function_name}() {
    unfunction '${function_name}'
    eval \"\$(${completion_command})\"
    \$_comps[${cmd_name}]
  }"

  compdef "${function_name}" "${cmd_name}"
}
