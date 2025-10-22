#!/bin/bash

#添加编译日期标识
sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_CONFIG-$WRT_DATE')/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")

CFG_FILE="./package/base-files/files/bin/config_generate"
#修改默认主机名
sed -i "s/hostname='.*'/hostname='${WRT_CONFIG##*-}'/g" $CFG_FILE

#修改qca-nss-drv启动顺序
NSS_DRV="./feeds/nss_packages/qca-nss-drv/files/qca-nss-drv.init"
if [ -f "$NSS_DRV" ]; then
	sed -i 's/START=.*/START=85/g' $NSS_DRV
	echo "qca-nss-drv has been fixed!"
fi

#修改qca-nss-pbuf启动顺序
NSS_PBUF="./package/kernel/mac80211/files/qca-nss-pbuf.init"
if [ -f "$NSS_PBUF" ]; then
	sed -i 's/START=.*/START=86/g' $NSS_PBUF
	echo "qca-nss-pbuf has been fixed!"
fi

#修改shell为zsh
PASSWD_PATH="./package/base-files/files/etc/passwd"
if [ -f "$PASSWD_PATH" ]; then
	sed -i 's/\/bin\/ash/\/usr\/bin\/zsh/g' $PASSWD_PATH
	echo "shell has been change zsh!"
fi

#高通平台调整
DTS_PATH="./target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/"
if [[ "${WRT_CONFIG##*-}" == "JDC1800" ]]; then
	#无WIFI配置调整Q6大小
	find $DTS_PATH -type f ! -iname '*nowifi*' -exec sed -i 's/ipq\(6018\|8074\).dtsi/ipq\1-nowifi.dtsi/g' {} +
	echo "qualcommax set up nowifi successfully!"
fi
