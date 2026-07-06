#!/usr/bin/env bash
# 在 Wallpaper 根目录执行

# ----- 自定义词表（可增删）-----
NAMES=("刘亦菲" "倪妮" "杨幂" "赵丽颖" "宋昕冉" "杨晨晨" "陈丽君" "王秋紫" "克拉" "昕予" "张静燕" "陈一" "芸斐")
PREFIXES=("极品" "性感女神" "清纯" "文艺古风" "少女" "阳光少年" "奇幻梦境" "自然之美" "性感女生" "美女古装" "古风文艺" "性感" "文艺" "YOU物馆" "【哲风壁纸】二次元-动漫" "阳光少年" "海岸" "极光" "教会山" "旧城墙" "纳奇兹" "席尔山" "Twr_Mawr" "pexels" "unsplash" "wallhaven" "nasa" "pascal" "peter" "slava" "qrgme7" "qrlg1r" "rqjr21" "3q93ky" "3qzr96" "5yg183")
# ---------------------------------

# 临时目录，防止重名冲突
TMP_DIR="./rename_temp"
mkdir -p "$TMP_DIR"

find . -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) ! -path "./$TMP_DIR/*" ! -name "rename_core.sh" ! -name "final_rename.sh" -print0 | while IFS= read -r -d '' file; do
    # 跳过自身脚本
    [[ "$file" == "./rename_core.sh" || "$file" == "./final_rename.sh" || "$file" == "./README.md" ]] && continue

    dir=$(dirname "$file")
    base=$(basename "$file")
    name="${base%.*}"
    ext="${base##*.}"

    # 获取真实分辨率
    real_dims=$(identify -format "%wx%h" "$file" 2>/dev/null)
    if [ -z "$real_dims" ]; then
        echo "⚠️ 跳过（无法读取分辨率）：$file"
        continue
    fi

    # 从原文件名中提取核心词（优先人名，否则去除前缀取第一个词）
    core=""
    # 先尝试匹配人名
    for n in "${NAMES[@]}"; do
        if [[ "$name" == *"$n"* ]]; then
            core="$n"
            break
        fi
    done

    if [ -z "$core" ]; then
        # 清理多余符号，统一为下划线分隔
        clean=$(echo "$name" | sed -E 's/[[:space:]]+/_/g' | sed -E 's/[，,、()（）]+/_/g' | sed -E 's/_+/_/g' | sed -E 's/^_|_$//g')
        IFS='_' read -ra parts <<< "$clean"
        # 去除通用前缀
        found=0
        for p in "${parts[@]}"; do
            skip=0
            for pre in "${PREFIXES[@]}"; do
                if [[ "$p" == "$pre" ]]; then
                    skip=1
                    break
                fi
            done
            if [ $skip -eq 0 ] && [ -n "$p" ]; then
                # 进一步检查 p 是否为纯数字（如 "7"）或 "4800x3000" 等无意义词，是则跳过
                if [[ "$p" =~ ^[0-9]+$ || "$p" =~ ^[0-9]+x[0-9]+$ ]]; then
                    continue
                fi
                core="$p"
                found=1
                break
            fi
        done
        # 如果依然没找到，取第一个非空部分（去除纯数字、分辨率）
        if [ $found -eq 0 ]; then
            for p in "${parts[@]}"; do
                if [ -n "$p" ] && ! [[ "$p" =~ ^[0-9]+$ ]] && ! [[ "$p" =~ ^[0-9]+x[0-9]+$ ]]; then
                    core="$p"
                    found=1
                    break
                fi
            done
        fi
        # 极端情况：全部是数字或空，则用原文件名（去除重复分辨率）
        if [ $found -eq 0 ]; then
            core="${parts[0]}"
            [ -z "$core" ] && core="$name"
        fi
    fi

    # 构造新文件名
    newname="${core}_${real_dims}.${ext}"
    # 如果新文件名已存在（包括当前文件本身），则加数字后缀
    target="$dir/$newname"
    if [ -e "$target" ] && [ "$target" != "$file" ]; then
        counter=1
        while [ -e "$dir/${core}_${real_dims}_${counter}.${ext}" ]; do
            ((counter++))
        done
        newname="${core}_${real_dims}_${counter}.${ext}"
    fi

    # 重命名
    if [ "$base" != "$newname" ]; then
        mv -n "$file" "$dir/$newname" && echo "✅ $base → $newname"
    else
        echo "⏭️  $base 无需改动"
    fi
done

# 清理临时目录（如果有）
rm -rf "$TMP_DIR"
echo "🎉 完成！"
