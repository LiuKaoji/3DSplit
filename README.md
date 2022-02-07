## 3DSplit
![platform](https://img.shields.io/badge/platform-ios-lightgrey.svg)  

![preview](https://github.com/LiuKaoji/3DSplit/blob/main/screenshot.gif)

## 简介
基于Open3D对 obj模型进行拆分, 并保留原始UV坐标 
```none
┌────────────────────────────────┐
│   open3d::io::ReadTriangleMesh │
└───────────────┬────────────────┘    
                │  
┌───────────────▼──────────────────┐
│   BoundingBox Plane Intersect    │
└───────────────┬──────────────────┘ 
                │
┌───────────────▼──────────────────┐
│     Line Plane Intersect         │
└───────┬────────────────────┬─────┘ 
        │                    │        
┌───────▼──────┐    ┌────────▼───────┐
│UV / vertices │    │  UV / vertices │
│   triangle   │    │   triangle     │
│   new Mesh   │    │   new Mesh     │
└───────┬──────┘    └─────────┬──────┘
        │                     │     
┌───────▼─────────────────────▼──────┐
│                                    │
│ open3d::io::WriteTriangleMeshToOBJ │
│                                    │
└────────────────────────────────────┘
```


## 参考环境
```bash
$ MacOS 12.1
$ Xcode 13.0
```

## 调试
```bash
$ git clone https://github.com/LiuKaoji/3DSplit.git
$ 下载附件open3d XCframework 放置工程目录
$ ...
```

## 参考
```bash
https://gdbooks.gitbooks.io/3dcollisions/content/Chapter2/static_aabb_plane.html
```



