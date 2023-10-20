#!/bin/bash

if ! command -v pip &>/dev/null; then \
  apt install -y python3-pip; \
  pip install --break-system-packages -U yt-dlp
else
  pip install -U yt-dlp
fi



