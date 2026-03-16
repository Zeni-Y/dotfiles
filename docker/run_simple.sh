#!/usr/bin/env bash
# GPU 動作確認用
docker run --gpus all --rm ubuntu:22.04 nvidia-smi
