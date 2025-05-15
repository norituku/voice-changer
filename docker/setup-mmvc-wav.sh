#!/bin/bash

# ディレクトリの作成
mkdir -p upload_dir/temp
mkdir -p tmp_dir

# 環境変数の設定
export EX_PORT=${EX_PORT:-18888}
export EX_IP=$(cat /etc/hosts | grep $(hostname) | awk '{print $1}')

# 実行ユーザーの取得
USER_ID=${LOCAL_UID:-9001}
GROUP_ID=${LOCAL_GID:-9001}

# ユーザーとグループの作成
groupadd -g $GROUP_ID usergroup
useradd -u $USER_ID -g $GROUP_ID -s /bin/bash -m user

# 権限の設定
chown -R user:usergroup /voice-changer/server
chown -R user:usergroup /voice-changer/server/upload_dir
chown -R user:usergroup /voice-changer/server/tmp_dir

# サーバー実行
gosu user bash exec-mmvc-wav.sh $@ 