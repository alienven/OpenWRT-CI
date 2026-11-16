#!/bin/bash

#添加编译日期标识
sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_CONFIG-$WRT_DATE')/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")

#修改默认主机名
CFG_FILE="./package/base-files/files/bin/config_generate"
sed -i "s/hostname='.*'/hostname='${WRT_CONFIG##*-}'/g" $CFG_FILE

#高通平台调整
DTS_PATH="./target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/"
if [[ "${WRT_CONFIG##*-}" == "JDC1800" ]]; then
    #无WIFI配置调整Q6大小
    find $DTS_PATH -type f ! -iname '*nowifi*' -exec sed -i 's/ipq\(6018\|8074\).dtsi/ipq\1-nowifi.dtsi/g' {} +
    echo "qualcommax set up nowifi successfully!"
fi

# 补齐 honk 源码
# daeuniverse/openwrt-packages 不把上游 Rust 源码放进仓库（其 .gitignore 排除
# /honk/src/），而 honk/Makefile 的 Build/Prepare 在该目录缺失时会直接报错退出。
# Build/Compile 通过 GITHUB_REF=refs/tags/<tag> 取版本号，不依赖 git 历史。
HONK_PKG="./package/openwrt-packages/honk"
HONK_REV="v0.1.0-beta.6"

if [ -d "$HONK_PKG" ]; then
    if [ ! -d "$HONK_PKG/src" ]; then
        echo "honk: fetching upstream sources at $HONK_REV"
        git clone --depth=1 --single-branch --branch "$HONK_REV" \
        https://github.com/daeuniverse/honk.git "$HONK_PKG/src"
    else
        echo "honk: sources already present, skip clone"
    fi
    # build.sh 用 tag 核对二进制内嵌版本，tag 与 Makefile 的 HONK_GIT_TAG 必须一致
    MAKEFILE_TAG=$(sed -n 's/^HONK_GIT_TAG:=.*,\(v[^)]*\))/\1/p' "$HONK_PKG/Makefile" | head -n 1)
    if [ -n "$MAKEFILE_TAG" ] && [ "$MAKEFILE_TAG" != "$HONK_REV" ]; then
        echo "honk: WARNING package expects $MAKEFILE_TAG but cloned $HONK_REV"
    fi
    echo "honk: sources ready at $HONK_REV (package default ${MAKEFILE_TAG:-unknown})"
else
    echo "honk: package directory not found, skip"
fi
