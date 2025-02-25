import ARKit
import SceneKit
import Metal

// MARK: - simd_float4x4 拡張
extension simd_float4x4 {
    var position: SIMD3<Float> {
        return SIMD3<Float>(columns.3.x, columns.3.y, columns.3.z)
    }
}

// MARK: - ARMeshGeometry 拡張（頂点／インデックス取得）
extension ARMeshGeometry {
    func vertex(at index: UInt32) -> (Float, Float, Float) {
        assert(vertices.format == MTLVertexFormat.float3, "Expected vertex format to be float3")
        let offset = vertices.offset + vertices.stride * Int(index)
        let pointer = vertices.buffer.contents().advanced(by: offset)
        let vertex = pointer.assumingMemoryBound(to: (Float, Float, Float).self).pointee
        return vertex
    }
    
    func vertexIndicesOf(faceWithIndex faceIndex: Int) -> [UInt32] {
        let vertexCountPerFace = faces.indexCountPerPrimitive
        var indices: [UInt32] = []
        let bytesPerIndex = faces.bytesPerIndex  // 例: 4バイト (UInt32)
        let faceOffset = faceIndex * vertexCountPerFace * bytesPerIndex
        for i in 0..<vertexCountPerFace {
            let elementOffset = faceOffset + i * bytesPerIndex
            let pointer = faces.buffer.contents().advanced(by: elementOffset)
            let index = pointer.assumingMemoryBound(to: UInt32.self).pointee
            indices.append(index)
        }
        return indices
    }
}

// MARK: - QuickHull3D（簡易凸包再構築）
// 注意: 以下は非常に簡略化した実装です。実際にはより堅牢なアルゴリズムが必要です。
struct QuickHull3D {
    /// 与えられた点群から凸包の頂点と三角形インデックスを返す
    static func computeConvexHull(points: [SIMD3<Float>]) -> (vertices: [SIMD3<Float>], indices: [UInt32]) {
        guard points.count >= 4 else { return (points, []) }
        // ここでは簡易的に、各軸の極値を抽出し、重複除去後、最初の4点を凸包の頂点（四面体）とする
        let minX = points.min { $0.x < $1.x }!
        let maxX = points.max { $0.x < $1.x }!
        let minY = points.min { $0.y < $1.y }!
        let maxY = points.max { $0.y < $1.y }!
        let minZ = points.min { $0.z < $1.z }!
        let maxZ = points.max { $0.z < $1.z }!
        var hullSet = [minX, maxX, minY, maxY, minZ, maxZ]
        // 重複除去
        hullSet = Array(Set(hullSet))
        if hullSet.count < 4 {
            hullSet = Array(points.prefix(4))
        } else {
            hullSet = Array(hullSet.prefix(4))
        }
        let vertices = hullSet
        // 四面体の各面（頂点インデックス）の組み合わせ
        let indices: [UInt32] = [
            0, 1, 2,
            0, 1, 3,
            0, 2, 3,
            1, 2, 3
        ]
        return (vertices, indices)
    }
}

/// 統合された点群から再構築されたポリゴンメッシュを作成する関数
func createReconstructedMeshOverlay(from anchors: [ARMeshAnchor], cameraPosition: SIMD3<Float>) -> SCNNode? {
    var aggregatedPoints: [SIMD3<Float>] = []
    // 各アンカーから頂点を抽出し、2m以内の点のみ統合
    for anchor in anchors {
        let mesh = anchor.geometry
        let vertexCount = mesh.vertices.count
        for i in 0..<vertexCount {
            let v = mesh.vertex(at: UInt32(i))
            let worldV4 = anchor.transform * SIMD4<Float>(v.0, v.1, v.2, 1.0)
            let worldV = SIMD3<Float>(worldV4.x, worldV4.y, worldV4.z)
            if distance(worldV, cameraPosition) <= 2.0 {
                aggregatedPoints.append(worldV)
            }
        }
    }
    guard !aggregatedPoints.isEmpty else { return nil }
    
    // 再構築アルゴリズム（ここでは簡易凸包）を適用
    let hull = QuickHull3D.computeConvexHull(points: aggregatedPoints)
    
    // SCNGeometry を作成
    let vertexData = hull.vertices.withUnsafeBufferPointer { Data(buffer: $0) }
    let vertexSource = SCNGeometrySource(data: vertexData,
                                         semantic: .vertex,
                                         vectorCount: hull.vertices.count,
                                         usesFloatComponents: true,
                                         componentsPerVector: 3,
                                         bytesPerComponent: MemoryLayout<Float>.size,
                                         dataOffset: 0,
                                         dataStride: MemoryLayout<SIMD3<Float>>.stride)
    
    let indexData = hull.indices.withUnsafeBufferPointer { Data(buffer: $0) }
    let geometryElement = SCNGeometryElement(data: indexData,
                                             primitiveType: .triangles,
                                             primitiveCount: hull.indices.count / 3,
                                             bytesPerIndex: MemoryLayout<UInt32>.size)
    
    let geometry = SCNGeometry(sources: [vertexSource], elements: [geometryElement])
    let material = SCNMaterial()
    // 半透明の赤色で対象物を覆う
    material.diffuse.contents = UIColor.red.withAlphaComponent(0.3)
    material.isDoubleSided = true
    geometry.materials = [material]
    
    return SCNNode(geometry: geometry)
}

