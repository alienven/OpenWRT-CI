#!/bin/bash

#添加编译日期标识
sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_CONFIG-$WRT_DATE')/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")

CFG_FILE="./package/base-files/files/bin/config_generate"
#修改默认主机名
sed -i "s/hostname='.*'/hostname='${WRT_CONFIG##*-}'/g" $CFG_FILE

#高通平台调整
DTS_PATH="./target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/"
if [[ "${WRT_CONFIG##*-}" == "JDC1800" ]]; then
	#无WIFI配置调整Q6大小
	find $DTS_PATH -type f ! -iname '*nowifi*' -exec sed -i 's/ipq\(6018\|8074\).dtsi/ipq\1-nowifi.dtsi/g' {} +
	echo "qualcommax set up nowifi successfully!"
fi
