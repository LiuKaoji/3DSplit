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

```mermaid
graph LR
    A(开始)
    B[读取模型文件]
    C[计算顶点法向量]
    D[计算包围盒]
    E{判断平面与模型是否相交}
    F[分割模型]
    G[计算交点]
    H[创建临时Mesh]
    I[分割三角形]
    J[写入分割后的模型文件]
    K(结束)
    A --> B
    B --> C
    C --> D
    D --> E
    E --> F
    F --> G
    G --> H
    H --> I
    I --> J
    J --> K
```



### 编译
```
$ git clone https://github.com/LiuKaoji/3DSplit.git
$ cd 3DSplit
$ chmod +x init.sh
$ ./init.sh
```


## 参考
```bash
https://gdbooks.gitbooks.io/3dcollisions/content/Chapter2/static_aabb_plane.html
```



