#!/bin/bash

# 创建目录结构
mkdir -p ./3DSplit/3rdParty/Open3d

# 库文件下载链接
declare -a urls=(
  "https://github.com/LiuKaoji/3DSplit/releases/download/1.0/Assimp.xcframework.zip"
  "https://github.com/LiuKaoji/3DSplit/releases/download/1.0/Faiss.xcframework.zip"
  "https://github.com/LiuKaoji/3DSplit/releases/download/1.0/IrrXML.xcframework.zip"
  "https://github.com/LiuKaoji/3DSplit/releases/download/1.0/JPEG.xcframework.zip"
  "https://github.com/LiuKaoji/3DSplit/releases/download/1.0/libOpen3D.a.xcframework.zip"
  "https://github.com/LiuKaoji/3DSplit/releases/download/1.0/libOpen3D_3rdparty_jsoncpp.a.xcframework.zip"
  "https://github.com/LiuKaoji/3DSplit/releases/download/1.0/libOpen3D_3rdparty_lzf.a.xcframework.zip"
  "https://github.com/LiuKaoji/3DSplit/releases/download/1.0/libOpen3D_3rdparty_qhullcpp.a.xcframework.zip"
  "https://github.com/LiuKaoji/3DSplit/releases/download/1.0/libOpen3D_3rdparty_qhull_r.a.xcframework.zip"
  "https://github.com/LiuKaoji/3DSplit/releases/download/1.0/libOpen3D_3rdparty_rply.a.xcframework.zip"
  "https://github.com/LiuKaoji/3DSplit/releases/download/1.0/libpng.a.xcframework.zip"
  "https://github.com/LiuKaoji/3DSplit/releases/download/1.0/pybind.a.xcframework.zip"
  "https://github.com/LiuKaoji/3DSplit/releases/download/1.0/TBB.xcframework.zip"
)

total_count=${#urls[@]}

# 下载并解压库文件
for i in "${!urls[@]}"; do
  url="${urls[$i]}"
  file_name=$(basename $url)
  target_file_name="${file_name%.*}"
  remaining=$((total_count - i - 1))
  
  if [ ! -d "./3DSplit/3rd/Open3d/$target_file_name" ]; then
    echo "正在下载第 $((i + 1)) 个文件：$file_name (剩余 $remaining 个)..."
    curl -L -o "$file_name" $url
    echo "解压 $file_name ..."
    unzip -o -q "$file_name" -d ./3DSplit/3rd/Open3d
    echo "删除 $file_name ..."
    rm -f "$file_name"
  else
    echo "跳过第 $((i + 1)) 个文件：$file_name，已存在 (剩余 $remaining 个)..."
  fi
done

echo "所有库文件已成功下载并解压到 ./3DSplit/3rd/Open3d"
