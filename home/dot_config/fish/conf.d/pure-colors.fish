# pure-fish プロンプト設定
# pure.fish より先に読み込まれるため、set --global で先占することで
# _pure_set_default のデフォルト値が適用されなくなる

# 色設定（黒背景向け）
set --global pure_color_primary  cyan      # ディレクトリ
set --global pure_color_mute     yellow    # git ブランチ・ホスト名
set --global pure_color_success  green     # プロンプト（成功時）
set --global pure_color_warning  brmagenta # コマンド実行時間
set --global pure_color_info     brblue    # git 未プッシュ/未プル

# 補完候補の色（brblack は黒背景で見えないため上書き）
set --global fish_color_autosuggestion 666

# コンテナ検出を無効化
# SSH 接続中かつコンテナ内にいる場合、両方で user@hostname が表示されて重複するため
set --global pure_enable_container_detection false
