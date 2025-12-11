#!/bin/bash

# Uncomment a feed source
# sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# Add a feed source
# echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default
# echo 'src-git passwall2 https://github.com/xiaorouji/openwrt-passwall2.git' >>feeds.conf.default
# echo 'src-git lucky https://github.com/gdy666/luci-app-lucky.git' >>feeds.conf.default
# echo 'src-git modem https://github.com/FUjr/modem_feeds.git' >> feeds.conf.default
echo 'src-git easytier https://github.com/EasyTier/luci-app-easytier.git' >>feeds.conf.default
echo 'src-git nikki https://github.com/nikkinikki-org/OpenWrt-nikki.git' >>feeds.conf.default
echo 'src-git luci_app_xray https://github.com/yichya/luci-app-xray.git' >>feeds.conf.default
