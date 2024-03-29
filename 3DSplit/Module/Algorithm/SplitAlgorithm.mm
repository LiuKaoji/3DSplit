//
//  SplitAlgorithm.m
//  3DSplit
//
//  Created by kaoji on 2021/8/24.
//

#import "SplitAlgorithm.h"
#import <open3d/Open3D.h>
#include <unordered_map>
#include <unordered_set>
#include <queue>

struct TmpMesh {
    std::vector<Eigen::Vector3d> vertices;
    std::vector<Eigen::Vector3i> triangles;
    std::unordered_map<size_t, size_t> vertices_idx;
    std::vector<Eigen::Vector2d> triangle_uvs_;
};

@implementation SplitAlgorithm

-(void)splitWithPath:(NSString *)path Center:(SCNVector3)center Normal:(SCNVector3)normal Completed:(MeshCutBlock)complete{
    open3d::geometry::TriangleMesh mesh;
    bool rStatus = open3d::io::ReadTriangleMesh(path.UTF8String, mesh, true, true);
    if (!rStatus) {
        if(complete)
            complete(nil, nil);
    }
    mesh.ComputeVertexNormals();

    auto l_mesh = std::make_shared<open3d::geometry::TriangleMesh>(std::vector<Eigen::Vector3d>{}, std::vector<Eigen::Vector3i>{});
    auto r_mesh = std::make_shared<open3d::geometry::TriangleMesh>(std::vector<Eigen::Vector3d>{}, std::vector<Eigen::Vector3i>{});

    auto plane_center = Eigen::Vector3d(center.x, center.y, center.z);
    auto plane_normal = Eigen::Vector3d(normal.x, normal.y, normal.z);
    plane_normal.normalize();
    std::vector<size_t> r_tmp_mesh_intersected_pt_indices;
    MeshCut(mesh, plane_center, plane_normal, *l_mesh, *r_mesh, r_tmp_mesh_intersected_pt_indices);
    mesh.Clear();

    NSString *partAPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"partA.obj"];
    NSString *partBPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"partB.obj"];

    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t concurrentQueue = dispatch_queue_create("com.wynter.concurrentQueue", DISPATCH_QUEUE_CONCURRENT);

    __block bool partAStatus = NO;
    __block bool partBStatus = NO;

    dispatch_group_async(group, concurrentQueue, ^{
        partAStatus = open3d::io::WriteTriangleMeshToOBJ(partBPath.UTF8String, *r_mesh, false, false, true, true, true, true);
    });

    dispatch_group_async(group, concurrentQueue, ^{
        partBStatus = open3d::io::WriteTriangleMeshToOBJ(partAPath.UTF8String, *l_mesh, false, false, true, true, true, true);
    });

    dispatch_group_notify(group, concurrentQueue, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *partAMtlPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"partA.mtl"];
            NSString *partBMtlPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"partB.mtl"];
            NSString *copyTexturePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"diffuseColor.jpg"];
            NSString *texturePath = [[NSBundle mainBundle] pathForResource:@"diffuseColor" ofType:@"jpg"];
            NSString *sourceMtlPath= [[NSBundle mainBundle] pathForResource:@"ship" ofType:@"mtl"];
            [[NSFileManager defaultManager] removeItemAtPath:copyTexturePath error:nil];
            [[NSFileManager defaultManager] removeItemAtPath:partAMtlPath error:nil];
            [[NSFileManager defaultManager] removeItemAtPath:partBMtlPath error:nil];
            [[NSFileManager defaultManager] copyItemAtPath:sourceMtlPath toPath:partAMtlPath error:nil];
            [[NSFileManager defaultManager] copyItemAtPath:sourceMtlPath toPath:partBMtlPath error:nil];
            [[NSFileManager defaultManager] copyItemAtPath:texturePath toPath:copyTexturePath error:nil];

            if(complete && partAStatus && partBStatus){
                complete(partAPath, partBPath);
            }
        });

        l_mesh->Clear();
        r_mesh->Clear();
    });
}

/*
@brief 检测有向包围盒与平面是否相交
@param bound 有向包围盒
@param plane_center 平面的中心点
@param plane_normal 平面的法线向量
@return 是否相交
*/
bool BoundPlaneIntersect(open3d::geometry::OrientedBoundingBox const& bound,
                         Eigen::Vector3d const& plane_center,
                         Eigen::Vector3d const& plane_normal) {
    auto bound_center = bound.GetCenter();
    auto bound_extents = bound.GetMaxBound() - bound_center;
    // 计算b在L（t）上的投影间隔半径=b.c+t*p.n
    auto r = bound_extents.x() * std::abs(plane_normal.x()) + bound_extents.y() * std::abs(plane_normal.y()) + bound_extents.z() * std::abs(plane_normal.z());
    // 计算箱体中心距平面的距离
    auto s = (bound_center - plane_center).dot(plane_normal);
    // 当距离s在[-r，+r]间隔内时发生交叉
    return std::abs(s) <= r;
}

bool LinePlaneIntersect(Eigen::Vector3d const& p0,
                        Eigen::Vector3d const& p1,
                        Eigen::Vector3d const& plane_center,
                        Eigen::Vector3d const& plane_normal,
                        Eigen::Vector3d& intersect_point,
                        double epsilon = 1e-6) {  //std::numeric_limits<double>::epsilon()
    auto line_dir = (p1 - p0).normalized();
    auto d = plane_normal.dot(line_dir);
    if (std::abs(d) < epsilon)
        return false;
    auto t = (plane_normal.dot(plane_center) - plane_normal.dot(p0)) / d;
    intersect_point = p0 + line_dir * t;
    return true;
}

/*
 *          |  /| v1
 *          | / |
 *          |/  |
 *       i0 |   |
 *         /|   |
 *        / |   |
 *    v0 /__|___| v2
 *          | i1
 */
bool TrianglePlaneIntersect(std::vector<Eigen::Vector3d> const& vertices,
                            std::vector<Eigen::Vector3i> const& triangles,
                            size_t triangle_idx,
                            Eigen::Vector3d const& plane_center,
                            Eigen::Vector3d const& plane_normal,
                            TmpMesh& l_tmp_mesh,
                            TmpMesh& r_tmp_mesh,
                            std::vector<size_t>& r_tmp_mesh_intersected_pt_indices,
                            std::vector<Eigen::Vector2d> const& triangle_uvs) {
    auto triangle = triangles[triangle_idx];

    auto is_triangle_vertices_in_mesh = [](Eigen::Vector3i triangle, TmpMesh const& mesh) {
        return std::array<bool, 3>{mesh.vertices_idx.find(triangle.x()) != mesh.vertices_idx.end(),
                                   mesh.vertices_idx.find(triangle.y()) != mesh.vertices_idx.end(),
                                   mesh.vertices_idx.find(triangle.z()) != mesh.vertices_idx.end()};
    };

    // 三角形顶点都在一侧网格中
    auto bls = is_triangle_vertices_in_mesh(triangle, l_tmp_mesh);
    if (bls[0] == bls[1] && bls[1] == bls[2]) {
        bls[0] ? l_tmp_mesh.triangles.emplace_back(l_tmp_mesh.vertices_idx[triangle.x()], l_tmp_mesh.vertices_idx[triangle.y()], l_tmp_mesh.vertices_idx[triangle.z()])
               : r_tmp_mesh.triangles.emplace_back(r_tmp_mesh.vertices_idx[triangle.x()], r_tmp_mesh.vertices_idx[triangle.y()], r_tmp_mesh.vertices_idx[triangle.z()]);

        // uv和顶点对应，一个三角形有三个顶点，三个一组取就可
        if (bls[0]) {
            l_tmp_mesh.triangle_uvs_.emplace_back(triangle_uvs[triangle_idx * 3]);
            l_tmp_mesh.triangle_uvs_.emplace_back(triangle_uvs[triangle_idx * 3 + 1]);
            l_tmp_mesh.triangle_uvs_.emplace_back(triangle_uvs[triangle_idx * 3 + 2]);
        } else {
            r_tmp_mesh.triangle_uvs_.emplace_back(triangle_uvs[triangle_idx * 3]);
            r_tmp_mesh.triangle_uvs_.emplace_back(triangle_uvs[triangle_idx * 3 + 1]);
            r_tmp_mesh.triangle_uvs_.emplace_back(triangle_uvs[triangle_idx * 3 + 2]);
        }
        return false;
    }

    // 寻找孤立的顶点
    int v0 = (bls[0] != bls[1]) ? (bls[0] != bls[2] ? 0 : 1) : 2;
    int v1 = (v0 + 1) % 3;
    int v2 = (v0 + 2) % 3;

    // 获取插入点
    Eigen::Vector3d i0, i1;
    LinePlaneIntersect(vertices[triangle(v0)], vertices[triangle(v1)], plane_center, plane_normal, i0);
    LinePlaneIntersect(vertices[triangle(v0)], vertices[triangle(v2)], plane_center, plane_normal, i1);

    auto Nl = l_tmp_mesh.vertices.size();
    auto Nr = r_tmp_mesh.vertices.size();
    l_tmp_mesh.vertices.push_back(i0);
    l_tmp_mesh.vertices.push_back(i1);
    r_tmp_mesh.vertices.push_back(i0);
    r_tmp_mesh.vertices.push_back(i1);

    r_tmp_mesh_intersected_pt_indices.push_back(Nr);
    r_tmp_mesh_intersected_pt_indices.push_back(Nr + 1);

    // 创建新三角形
    bls[v0] ? l_tmp_mesh.triangles.emplace_back(l_tmp_mesh.vertices_idx[triangle(v0)], Nl, Nl + 1)
            : r_tmp_mesh.triangles.emplace_back(r_tmp_mesh.vertices_idx[triangle(v0)], Nr, Nr + 1);
    bls[v1] ? l_tmp_mesh.triangles.emplace_back(Nl, l_tmp_mesh.vertices_idx[triangle(v1)], l_tmp_mesh.vertices_idx[triangle(v2)])
            : r_tmp_mesh.triangles.emplace_back(Nr, r_tmp_mesh.vertices_idx[triangle(v1)], r_tmp_mesh.vertices_idx[triangle(v2)]);
    bls[v2] ? l_tmp_mesh.triangles.emplace_back(l_tmp_mesh.vertices_idx[triangle(v2)], Nl + 1, Nl)
            : r_tmp_mesh.triangles.emplace_back(r_tmp_mesh.vertices_idx[triangle(v2)], Nr + 1, Nr);


    if (bls[0]) {
        l_tmp_mesh.triangle_uvs_.emplace_back(triangle_uvs[triangle_idx * 3]);
        l_tmp_mesh.triangle_uvs_.emplace_back(triangle_uvs[triangle_idx * 3 + 1]);
        l_tmp_mesh.triangle_uvs_.emplace_back(triangle_uvs[triangle_idx * 3 + 2]);
    } else {
        r_tmp_mesh.triangle_uvs_.emplace_back(triangle_uvs[triangle_idx * 3]);
        r_tmp_mesh.triangle_uvs_.emplace_back(triangle_uvs[triangle_idx * 3 + 1]);
        r_tmp_mesh.triangle_uvs_.emplace_back(triangle_uvs[triangle_idx * 3 + 2]);
    }

    if (bls[1]) {
        l_tmp_mesh.triangle_uvs_.emplace_back(triangle_uvs[triangle_idx * 3]);
        l_tmp_mesh.triangle_uvs_.emplace_back(triangle_uvs[triangle_idx * 3 + 1]);
        l_tmp_mesh.triangle_uvs_.emplace_back(triangle_uvs[triangle_idx * 3 + 2]);
    } else {
        r_tmp_mesh.triangle_uvs_.emplace_back(triangle_uvs[triangle_idx * 3]);
        r_tmp_mesh.triangle_uvs_.emplace_back(triangle_uvs[triangle_idx * 3 + 1]);
        r_tmp_mesh.triangle_uvs_.emplace_back(triangle_uvs[triangle_idx * 3 + 2]);
    }

    if (bls[2]) {
        l_tmp_mesh.triangle_uvs_.emplace_back(triangle_uvs[triangle_idx * 3]);
        l_tmp_mesh.triangle_uvs_.emplace_back(triangle_uvs[triangle_idx * 3 + 1]);
        l_tmp_mesh.triangle_uvs_.emplace_back(triangle_uvs[triangle_idx * 3 + 2]);
    } else {
        r_tmp_mesh.triangle_uvs_.emplace_back(triangle_uvs[triangle_idx * 3]);
        r_tmp_mesh.triangle_uvs_.emplace_back(triangle_uvs[triangle_idx * 3 + 1]);
        r_tmp_mesh.triangle_uvs_.emplace_back(triangle_uvs[triangle_idx * 3 + 2]);
    }

    return true;
}

/**
 * @brief 将输入的网格根据指定平面分割成两部分
 * @param mesh 待分割的网格
 * @param plane_center 平面的中心点
 * @param plane_normal 平面的法线向量
 * @param l_mesh 分割后的左侧网格
 * @param r_mesh 分割后的右侧网格
 * @param r_tmp_mesh_intersected_pt_indices 与平面相交的点索引
 * @return 是否成功分割
 */
bool MeshCut(open3d::geometry::TriangleMesh const& mesh,
             Eigen::Vector3d const& plane_center,
             Eigen::Vector3d const& plane_normal,
             open3d::geometry::TriangleMesh& l_mesh,
             open3d::geometry::TriangleMesh& r_mesh,
             std::vector<size_t>& r_tmp_mesh_intersected_pt_indices) {
    // 1. 检查边界框是否相交
    if (!BoundPlaneIntersect(mesh.GetOrientedBoundingBox(), plane_center, plane_normal)){
        std::cout << "平面未与模型相交!!!!!!!!!!!" << mesh.vertices_.size() << std::endl;
        return false;
    }

    TmpMesh l_tmp_mesh, r_tmp_mesh;

    // 2.分离顶点
    auto& vertices = mesh.vertices_;
//    auto& uvs = mesh.triangle_uvs_;
    auto N = vertices.size();
    l_tmp_mesh.vertices.reserve(N);
    l_tmp_mesh.vertices_idx.reserve(N);
    r_tmp_mesh.vertices.reserve(N);
    r_tmp_mesh.vertices_idx.reserve(N);
    for (size_t i = 0; i < N; i++) {
        if ((vertices[i] - plane_center).dot(plane_normal) >= 0) {
            l_tmp_mesh.vertices.push_back(vertices[i]);
            l_tmp_mesh.vertices_idx.insert({ i, l_tmp_mesh.vertices.size() - 1 });
        }
        else {
            r_tmp_mesh.vertices.push_back(vertices[i]);
            r_tmp_mesh.vertices_idx.insert({ i, r_tmp_mesh.vertices.size() - 1 });
        }
    }

    //  如果网格的某个顶点为空，则不相交
    if (l_tmp_mesh.vertices.empty() || r_tmp_mesh.vertices.empty())
        return false;

    // 3.分离三角形并切割与平面相交的三角形
    auto& triangles = mesh.triangles_;
    auto& triangle_uvs_ = mesh.triangle_uvs_;
    auto M = triangles.size();
    auto U = triangle_uvs_.size();
    l_tmp_mesh.triangles.reserve(M);
    r_tmp_mesh.triangles.reserve(M);
    l_tmp_mesh.triangle_uvs_.reserve(U);
    r_tmp_mesh.triangle_uvs_.reserve(U);
    r_tmp_mesh_intersected_pt_indices.reserve(M);
    for (auto i = 0; i < M; i++)
        TrianglePlaneIntersect(vertices, triangles, i, plane_center, plane_normal, l_tmp_mesh, r_tmp_mesh, r_tmp_mesh_intersected_pt_indices, triangle_uvs_);

    l_tmp_mesh.vertices.shrink_to_fit();
    l_tmp_mesh.triangles.shrink_to_fit();
    l_tmp_mesh.triangle_uvs_.shrink_to_fit();
    r_tmp_mesh.vertices.shrink_to_fit();
    r_tmp_mesh.triangles.shrink_to_fit();
    r_tmp_mesh.triangle_uvs_.shrink_to_fit();
    r_tmp_mesh_intersected_pt_indices.shrink_to_fit();

    // 4.将结果指定给l_mesh, r_mesh
    l_mesh = open3d::geometry::TriangleMesh(l_tmp_mesh.vertices, l_tmp_mesh.triangles);
    l_mesh.triangle_uvs_ = l_tmp_mesh.triangle_uvs_;
    r_mesh = open3d::geometry::TriangleMesh(r_tmp_mesh.vertices, r_tmp_mesh.triangles);
    r_mesh.triangle_uvs_ = r_tmp_mesh.triangle_uvs_;
    return true;
}

@end
