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

    # honk 必须用 rustup 装的工具链，不能用 feeds 编出来的 rust/host
    # OpenWrt 打包时把 staging_dir/host/bin 放在 PATH 最前（include/rules.mk 的
    # TARGET_PATH_PKG），而 feeds/packages/lang/rust 的 Host/Install 把 rustc/cargo
    # 1.96.x 装进了同一个目录。于是 rustup 依 rust-toolchain.toml 选版本的行为被
    # 绕过，aya 0.16 / aya-obj 0.6 要求的 rustc 1.98.0 得不到满足，报
    #   error: rustc 1.96.1 is not supported by the following packages
    # build.sh 是纯 shell 脚本，Makefile 里由 sh "$(PKG_DIR)/build.sh" 直接调用
    # （不复制进 build_dir），所以在它开头把 rustup 的 bin 提到 PATH 最前即可。
    HONK_SH="$HONK_PKG/build.sh"
    if [ ! -f "$HONK_SH" ]; then
        echo "honk: $HONK_SH not found, skip rustup PATH patch"
    else
        # 用 awk 在 "set -eu" 之后插入三行，不用 sed 的 a 命令：多行插入在
        # BSD/GNU sed 上的转义写法不一致，容易静默插错地方。
        # awk 找不到 "set -eu" 会以 3 退出，下面据此报错而不是默默放行。
        HONK_INS1='export PATH="${HOME}/.cargo/bin:${PATH}"'
        HONK_INS2='[ -x "${HOME}/.cargo/bin/cargo" ] || { echo "honk: rustup cargo missing at ${HOME}/.cargo/bin/cargo" >&2; exit 1; }'
        HONK_INS3='echo " honk: rustc $(rustc --version 2>&1)" >&2'

        if awk -v a="$HONK_INS1" -v b="$HONK_INS2" -v c="$HONK_INS3" '
            { print }
            $0 ~ /^set -eu[[:space:]]*$/ { print a; print b; print c; done = 1 }
            END { if (!done) exit 3 }
        ' "$HONK_SH" > "$HONK_SH.new"; then
            mv -f "$HONK_SH.new" "$HONK_SH"
            chmod +x "$HONK_SH"
            echo "honk: patched build.sh to prefer the rustup toolchain"
        else
            rm -f "$HONK_SH.new"
            # 上游改了 build.sh 的开头（没有独立的 "set -eu" 行）就会走到这里。
            # 静默失败会让下一次构建又白跑几小时，所以直接报错。
            echo "honk: ERROR: failed to patch $HONK_SH (no standalone 'set -eu' line?)"
            exit 1
        fi
    fi
else
    echo "honk: package directory not found, skip"
fi
