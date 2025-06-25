# RoaringBitmap

[English](README.md) | [简体中文](README_zh_CN.md)


[English](https://github.com/kesmeey/RoaringBitmap/blob/main/README.md) | [简体中文](https://github.com/kesmeey/RoaringBitmap/blob/master/README_zh_CN.md)

一个用 MoonBit 实现的高性能 RoaringBitmap，这是一种压缩位图数据结构，专为大型稀疏整数集合设计。RoaringBitmap 在保持快速操作的同时提供优秀的压缩率，广泛应用于数据库、搜索引擎和分析系统中。

## 🚀 核心特性

• 📦 **智能压缩** – 根据数据密度自动选择最优容器类型  
• ⚡ **高速操作** – 插入、删除、查询操作时间复杂度近似 O(1)  
• 🔧 **动态优化** – 自动在数组、位图、运行长度编码容器间转换  
• 📊 **内存高效** – 相比传统位图节省高达 90% 的内存  
• 🎯 **集合运算** – 支持并集、交集、差集、异或等完整集合操作  
• 🔄 **批量操作** – 高效的批量插入和操作，适合大数据处理  
• 📈 **可扩展性** – 支持 32 位无符号整数范围 (0 到 4,294,967,295)  
• 🔍 **丰富查询** – 提供最值查询、范围查询、排名查询等高级功能  
• 📊 **统计分析** – 详细的内存使用和性能统计信息

## 📥 安装
```bash
moon add kesmeey/RoaringBitmap
```

## 🚀 使用指南

### 🔨 创建 RoaringBitmap
多种方式创建和初始化 RoaringBitmap。

```moonbit
// 创建空的 bitmap
  let bitmap = @RoaringBitmap.new()

// 从单个值创建
  let single = @RoaringBitmap.singleton(42U)

// 从数组创建
  let values = [1U, 3U, 5U, 7U, 9U, 100U, 1000U]
  let bitmap = @RoaringBitmap.from_array(values)
```

### ➕ 添加和删除元素
使用 `add()` 和 `remove()` 方法操作集合元素。

```moonbit
  let mut bitmap = @RoaringBitmap.new()

  // 添加单个元素
  bitmap = bitmap.add(10U)
  bitmap = bitmap.add(20U)
  bitmap = bitmap.add(30U)

  // 批量添加（高性能）
  let new_values = [100U, 200U, 300U, 65536U, 131072U]
  bitmap = bitmap.add_many(new_values)

  // 移除元素
  bitmap = bitmap.remove(20U)

  println("当前大小: \{bitmap.size()}")  // 输出元素数量
```

### 🔍 查询操作
检查元素存在性和获取集合信息。

```moonbit
  let bitmap = @RoaringBitmap.from_array([1U, 10U, 100U, 1000U, 10000U])

  // 检查元素是否存在
  if bitmap.contains(100U) {
    println("100 存在于集合中")
  }

  // 获取最小值和最大值
  match bitmap.min() {
    Some(min_val) => println("最小值: \{min_val}")
    None => println("集合为空")
  }

  match bitmap.max() {
    Some(max_val) => println("最大值: \{max_val}")
    None => println("集合为空")
  }

  // 基本信息
  println("集合大小: \{bitmap.size()}")
  println("是否为空: \{bitmap.is_empty()}")
```

### 🎯 集合运算操作
执行高效的集合运算，支持完整的集合代数。

```moonbit
  let set1 = @RoaringBitmap.from_array([1U, 2U, 3U, 4U, 5U])
  let set2 = @RoaringBitmap.from_array([4U, 5U, 6U, 7U, 8U])

  // 并集 (A ∪ B)
  let union_result = set1.union(set2)
  println("并集大小: \{union_result.size()}")  // 8 个元素

  // 交集 (A ∩ B)
  let intersect_result = set1.intersect(set2)
  println("交集大小: \{intersect_result.size()}")  // 2 个元素 {4, 5}

  // 差集 (A - B)
  let diff_result = set1.difference(set2)
  println("差集大小: \{diff_result.size()}")  // 3 个元素 {1, 2, 3}

  // 对称差集 / 异或 (A ⊕ B)
  let xor_result = set1.xor(set2)
  println("异或大小: \{xor_result.size()}")  // 6 个元素 {1, 2, 3, 6, 7, 8}
```

### 🔗 集合关系检查
检查集合之间的包含关系和相似度。

```moonbit
  let big_set = @RoaringBitmap.from_array([1U, 2U, 3U, 4U, 5U, 6U, 7U, 8U])
  let small_set = @RoaringBitmap.from_array([2U, 4U, 6U])
  let other_set = @RoaringBitmap.from_array([2U, 4U, 6U])

  // 子集检查
  if small_set.is_subset(big_set) {
    println("small_set 是 big_set 的子集")
  }

  // 相等性检查
  if small_set.equals(other_set) {
    println("两个集合相等")
  }

  // Jaccard 相似度
  let similarity = big_set.jaccard_similarity(small_set)
  println("Jaccard 相似度: \{similarity}")
```

### 🔍 高级查询功能
范围查询、迭代和数据转换操作。

```moonbit
  let bitmap = @RoaringBitmap.from_array([1U, 5U, 10U, 15U, 20U, 25U, 30U, 100U])

  // 范围查询
  let range_result = bitmap.range(10U, 25U)
  println("范围 [10, 25] 内的元素数: \{range_result.size()}")

  // 迭代所有元素
  println("所有元素:")
  bitmap.iter(fn(value) {
    println("  \{value}")
  })

  // 转换为数组
  let array = bitmap.to_array()
  println("转换为数组: \{array}")

  // 清空集合
  let cleared = bitmap.clear()
  assert_true!(cleared.is_empty())
```

### 📊 性能统计和调试
获取详细的内存使用和性能信息。

```moonbit
  // 创建包含不同类型数据的 bitmap
  let sparse_data = [1U, 100U, 1000U, 10000U]  // 稀疏数据 -> 数组容器
  let dense_data = []
  for i = 0; i < 5000; i = i + 1 {
    dense_data.push(i.reinterpret_as_uint())    // 密集数据 -> 位图容器
  }

  let sparse_bitmap = @RoaringBitmap.from_array(sparse_data)
  let dense_bitmap = @RoaringBitmap.from_array(dense_data)

  // 获取统计信息
  let sparse_stats = sparse_bitmap.get_stats()
  println("稀疏数据统计:")
  println("  总容器数: \{sparse_stats.total_containers}")
  println("  数组容器: \{sparse_stats.array_containers}")
  println("  位图容器: \{sparse_stats.bitmap_containers}")
  println("  总字节数: \{sparse_stats.total_bytes}")
  println("  压缩率: \{sparse_stats.compression_ratio}")

  let dense_stats = dense_bitmap.get_stats()
  println("密集数据统计:")
  println("  总容器数: \{dense_stats.total_containers}")
  println("  位图容器: \{dense_stats.bitmap_containers}")
  println("  压缩率: \{dense_stats.compression_ratio}")
```

### 🔄 大数据集处理
处理大规模数据和跨容器操作。

```moonbit
  // 创建大型数据集
  let mut large_bitmap = @RoaringBitmap.new()

  // 添加跨多个 16 位高位的数据
  let large_values = [
    1U,          // 高 16 位: 0
    65536U,      // 高 16 位: 1
    131072U,     // 高 16 位: 2
    196608U,     // 高 16 位: 3
    4294967295U  // 高 16 位: 65535 (最大值)
  ]

  large_bitmap = large_bitmap.add_many(large_values)

  // 验证跨容器操作
  println("跨容器 bitmap 大小: \{large_bitmap.size()}")
  println("最小值: \{large_bitmap.min()}")
  println("最大值: \{large_bitmap.max()}")

  // 创建连续数据（适合运行长度编码）
  let consecutive = []
  for i = 10000; i < 15000; i = i + 1 {
    consecutive.push(i.reinterpret_as_uint())
  }
  let rle_bitmap = @RoaringBitmap.from_array(consecutive)
  let rle_stats = rle_bitmap.get_stats()
  println("RLE 数据压缩率: \{rle_stats.compression_ratio}")
```

### 🎛️ 复杂集合操作
组合多个集合运算实现复杂查询。

```moonbit
  let set_a = @RoaringBitmap.from_array([1U, 2U, 3U, 4U, 5U])
  let set_b = @RoaringBitmap.from_array([4U, 5U, 6U, 7U, 8U])
  let set_c = @RoaringBitmap.from_array([1U, 3U, 5U, 7U, 9U])

  // 复杂查询: (A ∪ B) ∩ C
  let union_ab = set_a.union(set_b)        // {1,2,3,4,5,6,7,8}
  let result1 = union_ab.intersect(set_c)  // {1,3,5,7}
  println("(A ∪ B) ∩ C 结果大小: \{result1.size()}")

  // 复杂查询: A - (B ∩ C)
  let intersect_bc = set_b.intersect(set_c)  // {5,7}
  let result2 = set_a.difference(intersect_bc)  // {1,2,3,4}
  println("A - (B ∩ C) 结果大小: \{result2.size()}")

  // 三元异或: A ⊕ B ⊕ C
  let xor_ab = set_a.xor(set_b)
  let result3 = xor_ab.xor(set_c)
  println("A ⊕ B ⊕ C 结果大小: \{result3.size()}")
```

## 📊 性能特征

| 操作 | 时间复杂度 | 空间复杂度 | 说明 |
|------|-----------|-----------|------|
| `new()` | O(1) | O(1) | 创建空 bitmap |
| `add()` | O(1) | O(1) | 添加单个元素 |
| `remove()` | O(1) | O(1) | 移除单个元素 |
| `contains()` | O(1) | O(1) | 查询元素存在性 |
| `union()` | O(n+m) | O(n+m) | 两个 bitmap 并集 |
| `intersect()` | O(min(n,m)) | O(min(n,m)) | 两个 bitmap 交集 |
| `add_many()` | O(k log k) | O(k) | 批量添加 k 个元素 |
| `range()` | O(output) | O(output) | 范围查询 |
| `to_array()` | O(n) | O(n) | 转换为数组 |

其中：
- `n`, `m` = 两个 bitmap 的元素数量
- `k` = 批量操作的元素数量

## 🏗️ 实现细节

RoaringBitmap 使用三种容器类型自动优化存储：

### 📦 容器类型

1. **数组容器 (ArrayContainer)**
   - **用途**：稀疏数据 (< 4096 个元素)
   - **存储**：排序的 `UInt16` 数组
   - **优势**：内存效率高，查询快速

2. **位图容器 (BitmapContainer)**  
   - **用途**：密集数据 (≥ 4096 个元素)
   - **存储**：1024 个 `UInt64` 字的位图
   - **优势**：集合运算速度极快

3. **运行长度编码容器 (RunContainer)**
   - **用途**：连续数据段
   - **存储**：(起始位置, 长度) 对的数组
   - **优势**：连续数据压缩率极高

### 🔄 自动优化

RoaringBitmap 根据数据特征自动选择最优容器：

```moonbit
  // 稀疏数据 -> 数组容器
  let sparse = @RoaringBitmap.from_array([1U, 100U, 1000U])

  // 密集数据 -> 位图容器  
  let dense_values = []
  for i = 0; i < 5000; i = i + 1 {
    dense_values.push(i.reinterpret_as_uint())
  }
  let dense = @RoaringBitmap.from_array(dense_values)

  // 连续数据 -> 运行长度编码容器
  let consecutive_values = []
  for i = 10000; i < 15000; i = i + 1 {
    consecutive_values.push(i.reinterpret_as_uint())
  }
  let consecutive = @RoaringBitmap.from_array(consecutive_values)
```

### 📈 容器转换阈值

- **数组 → 位图**：元素数量 ≥ 4096
- **位图 → 数组**：元素数量 < 4096  
- **运行长度编码**：当连续段数量显著少于总元素数时使用

## 🎯 使用场景

### 💾 数据库索引
```moonbit
  // 用户 ID 集合
  let active_users = @RoaringBitmap.from_array([1001U, 1005U, 1010U, 1015U])
  let premium_users = @RoaringBitmap.from_array([1005U, 1010U, 1020U, 1025U])

  // 活跃的高级用户
  let active_premium = active_users.intersect(premium_users)
  println("活跃高级用户数: \{active_premium.size()}")
```

### 🔍 搜索引擎
```moonbit
  // 文档 ID 集合
  let keyword1_docs = @RoaringBitmap.from_array([1U, 5U, 10U, 15U])
  let keyword2_docs = @RoaringBitmap.from_array([3U, 5U, 15U, 20U])

  // 包含两个关键词的文档
  let both_keywords = keyword1_docs.intersect(keyword2_docs)
  let results = both_keywords.to_array()
  println("搜索结果文档 ID: \{results}")
```

### 📊 数据分析
```moonbit
  // 时间序列数据点
  let mut morning_events = @RoaringBitmap.new()
  let afternoon_events = @RoaringBitmap.new()

  // 添加事件时间戳
  for hour = 6; hour < 12; hour = hour + 1 {
    for minute = 0; minute < 60; minute = minute + 5 {
      let timestamp = (hour * 3600 + minute * 60).reinterpret_as_uint()
      morning_events = morning_events.add(timestamp)
    }
  }

  println("上午事件数: \{morning_events.size()}")
  let stats = morning_events.get_stats()
  println("压缩率: \{stats.compression_ratio}")
```

## 🔧 配置和调优

### 内存使用优化
```moonbit
  // 对于已知会有大量元素的场景，使用批量操作
  let large_dataset = []
  for i = 0; i < 100000; i = i + 1 {
    large_dataset.push(i.reinterpret_as_uint())
  }

  // 推荐：批量创建
  let bitmap = @RoaringBitmap.from_array(large_dataset)

  // 不推荐：逐个添加
  // let mut bitmap = @RoaringBitmap.new()
  // for value in large_dataset {
  //   bitmap = bitmap.add(value)
  // }
```

### 性能监控
```moonbit
  let bitmap = @RoaringBitmap.from_array([/* 数据 */]) //如[1,2,3]
  let stats = bitmap.get_stats()

  // 监控压缩效果
  if stats.compression_ratio > 2.0 {
    println("压缩效果良好")
  } else {
    println("考虑数据结构是否适合")
  }

  // 监控容器分布
  println("容器分布:")
  println("  数组容器: \{stats.array_containers}")
  println("  位图容器: \{stats.bitmap_containers}")  
  println("  运行容器: \{stats.run_containers}")
```

## 🆚 RoaringBitmap vs 传统位图

| 特性 | 传统位图 | RoaringBitmap |
|------|---------|---------------|
| **稀疏数据** | 效率低 | 高度优化 |
| **密集数据** | 效率高 | 同样高效 |
| **集合运算** | 快速 | 同样快速 |
| **压缩率** | 无压缩 | 智能压缩 |
| **适用场景** | 密集数据 | 通用场景 |



## 🤝 贡献

欢迎贡献代码！请遵循以下步骤：

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 📜 许可证

本项目基于 Apache-2.0 许可证。详情请参见 [LICENSE](LICENSE) 文件。

## 🔗 相关资源

- [RoaringBitmap 官方网站](https://roaringbitmap.org/)
- [MoonBit 语言文档](https://www.moonbitlang.com/docs/)
- [RoaringBitmap实现参考](https://github.com/RoaringBitmap/RoaringBitmap)

