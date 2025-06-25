///| 测试创建空的 RoaringBitmap
test "test_new" {
  let bitmap = @RoaringBitmap.new()
  assert_eq!(bitmap.is_empty(), true)
  assert_eq!(bitmap.size(), 0)
}

///| 测试单个值创建 RoaringBitmap
test "test_singleton" {
  let bitmap = @RoaringBitmap.singleton(42U)
  assert_eq!(bitmap.is_empty(), false)
  assert_eq!(bitmap.size(), 1)
  assert_eq!(bitmap.contains(42U), true)
  assert_eq!(bitmap.contains(43U), false)
}

///| 测试从数组创建 RoaringBitmap
test "test_from_array" {
  let values = [1U, 3U, 5U, 7U, 9U]
  let bitmap = @RoaringBitmap.from_array(values)
  assert_eq!(bitmap.size(), 5)
  for i = 0; i < values.length(); i = i + 1 {
    assert_eq!(bitmap.contains(values[i]), true)
  }
  assert_eq!(bitmap.contains(2U), false)
  assert_eq!(bitmap.contains(4U), false)
}

///| 测试添加元素
test "test_add" {
  let mut bitmap = @RoaringBitmap.new()

  // 添加单个元素
  bitmap = bitmap.add(10U)
  assert_eq!(bitmap.size(), 1)
  assert_eq!(bitmap.contains(10U), true)

  // 添加更多元素
  bitmap = bitmap.add(20U)
  bitmap = bitmap.add(30U)
  assert_eq!(bitmap.size(), 3)
  assert_eq!(bitmap.contains(20U), true)
  assert_eq!(bitmap.contains(30U), true)

  // 重复添加相同元素
  bitmap = bitmap.add(20U)
  assert_eq!(bitmap.size(), 3) // 大小不变
}

///| 测试移除元素
test "test_remove" {
  let mut bitmap = @RoaringBitmap.from_array([10U, 20U, 30U, 40U])

  // 移除存在的元素
  bitmap = bitmap.remove(20U)
  assert_eq!(bitmap.size(), 3)
  assert_eq!(bitmap.contains(20U), false)
  assert_eq!(bitmap.contains(10U), true)
  assert_eq!(bitmap.contains(30U), true)

  // 移除不存在的元素
  bitmap = bitmap.remove(50U)
  assert_eq!(bitmap.size(), 3) // 大小不变

  // 移除所有元素
  bitmap = bitmap.remove(10U)
  bitmap = bitmap.remove(30U)
  bitmap = bitmap.remove(40U)
  assert_eq!(bitmap.is_empty(), true)
}

///| 测试包含检查
test "test_contains" {
  let bitmap = @RoaringBitmap.from_array([1U, 100U, 1000U, 10000U])
  assert_eq!(bitmap.contains(1U), true)
  assert_eq!(bitmap.contains(100U), true)
  assert_eq!(bitmap.contains(1000U), true)
  assert_eq!(bitmap.contains(10000U), true)
  assert_eq!(bitmap.contains(0U), false)
  assert_eq!(bitmap.contains(2U), false)
  assert_eq!(bitmap.contains(999U), false)
  assert_eq!(bitmap.contains(10001U), false)
}

///| 测试并集操作
test "test_union" {
  let bitmap1 = @RoaringBitmap.from_array([1U, 2U, 3U])
  let bitmap2 = @RoaringBitmap.from_array([3U, 4U, 5U])
  let union_bitmap = bitmap1.union(bitmap2)
  assert_eq!(union_bitmap.size(), 5)
  assert_eq!(union_bitmap.contains(1U), true)
  assert_eq!(union_bitmap.contains(2U), true)
  assert_eq!(union_bitmap.contains(3U), true)
  assert_eq!(union_bitmap.contains(4U), true)
  assert_eq!(union_bitmap.contains(5U), true)
}

///| 测试交集操作
test "test_intersect" {
  let bitmap1 = @RoaringBitmap.from_array([1U, 2U, 3U, 4U])
  let bitmap2 = @RoaringBitmap.from_array([3U, 4U, 5U, 6U])
  let intersect_bitmap = bitmap1.intersect(bitmap2)
  assert_eq!(intersect_bitmap.size(), 2)
  assert_eq!(intersect_bitmap.contains(3U), true)
  assert_eq!(intersect_bitmap.contains(4U), true)
  assert_eq!(intersect_bitmap.contains(1U), false)
  assert_eq!(intersect_bitmap.contains(2U), false)
  assert_eq!(intersect_bitmap.contains(5U), false)
  assert_eq!(intersect_bitmap.contains(6U), false)
}

///| 测试差集操作
test "test_difference" {
  let bitmap1 = @RoaringBitmap.from_array([1U, 2U, 3U, 4U])
  let bitmap2 = @RoaringBitmap.from_array([3U, 4U, 5U, 6U])
  let diff_bitmap = bitmap1.difference(bitmap2)
  assert_eq!(diff_bitmap.size(), 2)
  assert_eq!(diff_bitmap.contains(1U), true)
  assert_eq!(diff_bitmap.contains(2U), true)
  assert_eq!(diff_bitmap.contains(3U), false)
  assert_eq!(diff_bitmap.contains(4U), false)
  assert_eq!(diff_bitmap.contains(5U), false)
}

///| 测试空集合操作
test "test_empty_operations" {
  let empty = @RoaringBitmap.new()
  let bitmap = @RoaringBitmap.from_array([1U, 2U, 3U])

  // 空集合并集
  let union_with_empty = bitmap.union(empty)
  assert_eq!(union_with_empty.size(), bitmap.size())

  // 空集合交集
  let intersect_with_empty = bitmap.intersect(empty)
  assert_eq!(intersect_with_empty.is_empty(), true)

  // 空集合差集
  let diff_with_empty = bitmap.difference(empty)
  assert_eq!(diff_with_empty.size(), bitmap.size())
  let empty_diff = empty.difference(bitmap)
  assert_eq!(empty_diff.is_empty(), true)
}

///| 测试大数值（跨不同高16位）
test "test_large_values" {
  let values = [
    1U, // 高16位: 0
     65536U, // 高16位: 1, 低16位: 0
     65537U, // 高16位: 1, 低16位: 1  
     131072U, // 高16位: 2, 低16位: 0
     4294967295U,
  ] // 高16位: 65535, 低16位: 65535
  let bitmap = @RoaringBitmap.from_array(values)
  assert_eq!(bitmap.size(), 5)
  for i = 0; i < values.length(); i = i + 1 {
    assert_eq!(bitmap.contains(values[i]), true)
  }
}

///| 测试数组容器转位图容器的阈值
test "test_array_to_bitmap_conversion" {
  let mut bitmap = @RoaringBitmap.new()

  // 添加大量元素，触发数组容器到位图容器的转换
  for i = 0; i < 5000; i = i + 1 {
    bitmap = bitmap.add(i.reinterpret_as_uint())
  }
  assert_eq!(bitmap.size(), 5000)

  // 验证一些关键元素
  assert_eq!(bitmap.contains(0U), true)
  assert_eq!(bitmap.contains(1000U), true)
  assert_eq!(bitmap.contains(4999U), true)
  assert_eq!(bitmap.contains(5000U), false)
}

///| 测试连续数值（适合运行长度编码）
test "test_consecutive_values" {
  let values = []
  // 创建连续的数值序列
  for i = 1000; i < 2000; i = i + 1 {
    values.push(i.reinterpret_as_uint())
  }
  let bitmap = @RoaringBitmap.from_array(values)
  assert_eq!(bitmap.size(), 1000)

  // 验证边界值
  assert_eq!(bitmap.contains(1000U), true)
  assert_eq!(bitmap.contains(1999U), true)
  assert_eq!(bitmap.contains(999U), false)
  assert_eq!(bitmap.contains(2000U), false)
}

///| 测试稀疏数据
test "test_sparse_data" {
  let values = []
  // 创建稀疏数据：每隔1000添加一个值
  for i = 0; i < 10; i = i + 1 {
    values.push((i * 1000).reinterpret_as_uint())
  }
  let bitmap = @RoaringBitmap.from_array(values)
  assert_eq!(bitmap.size(), 10)

  // 验证存在的值
  assert_eq!(bitmap.contains(0U), true)
  assert_eq!(bitmap.contains(1000U), true)
  assert_eq!(bitmap.contains(9000U), true)

  // 验证不存在的值
  assert_eq!(bitmap.contains(999U), false)
  assert_eq!(bitmap.contains(1001U), false)
}

///| 测试统计信息
test "test_statistics" {
  let bitmap = @RoaringBitmap.from_array([1U, 2U, 3U, 100U, 200U])
  let stats = bitmap.get_stats()
  assert_eq!(stats.total_containers > 0, true)
  assert_eq!(stats.total_bytes > 0, true)
  assert_eq!(stats.compression_ratio > 0.0, true)
}

///| 测试清空操作
test "test_clear" {
  let bitmap = @RoaringBitmap.from_array([1U, 2U, 3U, 4U, 5U])
  assert_eq!(bitmap.is_empty(), false)
  let cleared = bitmap.clear()
  assert_eq!(cleared.is_empty(), true)
  assert_eq!(cleared.size(), 0)
}

///| 测试转换为数组
test "test_to_array" {
  let original_values = [1U, 5U, 10U, 15U, 20U]
  let bitmap = @RoaringBitmap.from_array(original_values)
  let result_array = bitmap.to_array()
  assert_eq!(result_array.length(), original_values.length())

  // 验证第一个和最后一个元素
  assert_eq!(result_array[0], (1).reinterpret_as_uint())
  assert_eq!(result_array[4], (20).reinterpret_as_uint())
}

///| 测试边界情况
test "test_edge_cases" {
  // 测试最小值和最大值
  let bitmap = @RoaringBitmap.from_array([0U, 4294967295U])
  assert_eq!(bitmap.size(), 2)
  assert_eq!(bitmap.contains(0U), true)
  assert_eq!(bitmap.contains(4294967295U), true)

  // 测试相邻值
  let adjacent = @RoaringBitmap.from_array([65535U, 65536U])
  assert_eq!(adjacent.size(), 2)
  assert_eq!(adjacent.contains(65535U), true)
  assert_eq!(adjacent.contains(65536U), true)
}

///| 测试复杂的集合操作组合
test "test_complex_operations" {
  let bitmap1 = @RoaringBitmap.from_array([1U, 2U, 3U, 4U, 5U])
  let bitmap2 = @RoaringBitmap.from_array([4U, 5U, 6U, 7U, 8U])
  let bitmap3 = @RoaringBitmap.from_array([1U, 3U, 5U, 7U, 9U])

  // 复杂操作：(bitmap1 ∪ bitmap2) ∩ bitmap3
  let union_12 = bitmap1.union(bitmap2)
  let result = union_12.intersect(bitmap3)
  assert_eq!(result.size(), 4) // {1, 3, 5, 7}
  assert_eq!(result.contains(1U), true)
  assert_eq!(result.contains(3U), true)
  assert_eq!(result.contains(5U), true)
  assert_eq!(result.contains(7U), true)
  assert_eq!(result.contains(2U), false)
  assert_eq!(result.contains(9U), false)
}

///| 测试性能 - 大数据集
test "test_performance_large_dataset" {
  let mut bitmap = @RoaringBitmap.new()

  // 添加10000个元素（只添加偶数）
  for i = 0; i < 10000; i = i + 2 {
    bitmap = bitmap.add(i.reinterpret_as_uint())
  }
  assert_eq!(bitmap.size(), 5000)

  // 验证一些元素
  assert_eq!(bitmap.contains(0U), true)
  assert_eq!(bitmap.contains(9998U), true)
  assert_eq!(bitmap.contains(1U), false)
  assert_eq!(bitmap.contains(9999U), false)

  // 测试与另一个大集合的操作
  let mut bitmap2 = @RoaringBitmap.new()
  for i = 1; i < 10000; i = i + 2 { // 只添加奇数
    bitmap2 = bitmap2.add(i.reinterpret_as_uint())
  }
  let union_result = bitmap.union(bitmap2)
  assert_eq!(union_result.size(), 10000)
  let intersect_result = bitmap.intersect(bitmap2)
  assert_eq!(intersect_result.is_empty(), true) // 偶数和奇数没有交集
}

///| 测试错误处理和健壮性
test "test_robustness" {
  let bitmap = @RoaringBitmap.new()

  // 对空集合进行各种操作应该安全
  assert_eq!(bitmap.contains(0U), false)
  assert_eq!(bitmap.remove(100U).is_empty(), true)
  assert_eq!(bitmap.clear().is_empty(), true)
  let stats = bitmap.get_stats()
  assert_eq!(stats.total_containers, 0)
  assert_eq!(stats.total_bytes, 0)
}

///| 基准测试 - 不同容器类型的性能比较
test "test_container_types_performance" {
  // 数组容器场景：稀疏数据
  let sparse_values = [1U, 100U, 1000U, 10000U]
  let sparse_bitmap = @RoaringBitmap.from_array(sparse_values)
  let sparse_stats = sparse_bitmap.get_stats()
  assert_eq!(sparse_stats.array_containers >= 1, true)

  // 位图容器场景：密集数据
  let dense_values = []
  for i = 0; i < 5000; i = i + 1 {
    dense_values.push(i.reinterpret_as_uint())
  }
  let dense_bitmap = @RoaringBitmap.from_array(dense_values)
  let dense_stats = dense_bitmap.get_stats()
  assert_eq!(dense_stats.total_containers > 0, true)

  // 运行长度编码场景：连续数据
  let consecutive_values = []
  for i = 10000; i < 15000; i = i + 1 {
    consecutive_values.push(i.reinterpret_as_uint())
  }
  let consecutive_bitmap = @RoaringBitmap.from_array(consecutive_values)
  assert_eq!(consecutive_bitmap.size(), 5000)
}

///| 测试单容器边界情况
test "test_single_container_edge_cases" {
  // 测试刚好达到转换阈值的情况
  let mut bitmap = @RoaringBitmap.new()

  // 添加 ARRAY_CONTAINER_MAX_SIZE - 1 个元素
  for i = 0; i < 4095; i = i + 1 {
    bitmap = bitmap.add(i.reinterpret_as_uint())
  }
  assert_eq!(bitmap.size(), 4095)

  // 再添加一个元素，应该触发转换
  bitmap = bitmap.add(4095U)
  assert_eq!(bitmap.size(), 4096)
  assert_eq!(bitmap.contains(0U), true)
  assert_eq!(bitmap.contains(4095U), true)
}

///| 测试移除操作的容器转换
test "test_remove_container_conversion" {
  let mut bitmap = @RoaringBitmap.new()

  // 先添加大量元素（超过阈值）
  for i = 0; i < 5000; i = i + 1 {
    bitmap = bitmap.add(i.reinterpret_as_uint())
  }

  // 然后移除大部分元素
  for i = 1000; i < 5000; i = i + 1 {
    bitmap = bitmap.remove(i.reinterpret_as_uint())
  }
  assert_eq!(bitmap.size(), 1000)

  // 验证剩余元素
  for i = 0; i < 1000; i = i + 1 {
    assert_eq!(bitmap.contains(i.reinterpret_as_uint()), true)
  }
  assert_eq!(bitmap.contains(1000U), false)
}

///| 测试相等性检查
test "test_equals" {
  let bitmap1 = @RoaringBitmap.from_array([1U, 2U, 3U, 4U, 5U])
  let bitmap2 = @RoaringBitmap.from_array([1U, 2U, 3U, 4U, 5U])
  let bitmap3 = @RoaringBitmap.from_array([1U, 2U, 3U, 4U, 6U])
  assert_eq!(bitmap1.equals(bitmap2), true)
  assert_eq!(bitmap1.equals(bitmap3), false)
  assert_eq!(bitmap1.equals(@RoaringBitmap.new()), false)

  // 测试空bitmap相等
  let empty1 = @RoaringBitmap.new()
  let empty2 = @RoaringBitmap.new()
  assert_eq!(empty1.equals(empty2), true)
}

///| 测试最小值和最大值
test "test_min_max" {
  // 测试空bitmap
  let empty = @RoaringBitmap.new()
  assert_eq!(empty.min(), None)
  assert_eq!(empty.max(), None)

  // 测试单元素bitmap
  let single = @RoaringBitmap.singleton(42U)
  assert_eq!(single.min(), Some(42U))
  assert_eq!(single.max(), Some(42U))

  // 测试多元素bitmap
  let bitmap = @RoaringBitmap.from_array([10U, 5U, 100U, 1U, 50U])
  assert_eq!(bitmap.min(), Some(1U))
  assert_eq!(bitmap.max(), Some(100U))

  // 测试跨多个容器的情况
  let large_bitmap = @RoaringBitmap.from_array([1U, 65536U, 131072U])
  assert_eq!(large_bitmap.min(), Some(1U))
  assert_eq!(large_bitmap.max(), Some(131072U))
}

///| 测试子集检查
test "test_is_subset" {
  let bitmap1 = @RoaringBitmap.from_array([1U, 2U, 3U])
  let bitmap2 = @RoaringBitmap.from_array([1U, 2U, 3U, 4U, 5U])
  let bitmap3 = @RoaringBitmap.from_array([2U, 3U, 4U])
  let empty = @RoaringBitmap.new()

  // 基本子集测试
  assert_eq!(bitmap1.is_subset(bitmap2), true)
  assert_eq!(bitmap2.is_subset(bitmap1), false)
  assert_eq!(bitmap1.is_subset(bitmap3), false)

  // 空集是任何集合的子集
  assert_eq!(empty.is_subset(bitmap1), true)
  assert_eq!(empty.is_subset(empty), true)

  // 集合是自己的子集
  assert_eq!(bitmap1.is_subset(bitmap1), true)

  // 跨容器的子集测试
  let small_multi = @RoaringBitmap.from_array([1U, 65536U])
  let large_multi = @RoaringBitmap.from_array([1U, 2U, 65536U, 65537U, 131072U])
  assert_eq!(small_multi.is_subset(large_multi), true)
  assert_eq!(large_multi.is_subset(small_multi), false)
}

///| 测试XOR操作
test "test_xor" {
  let bitmap1 = @RoaringBitmap.from_array([1U, 2U, 3U, 4U])
  let bitmap2 = @RoaringBitmap.from_array([3U, 4U, 5U, 6U])
  let xor_result = bitmap1.xor(bitmap2)
  assert_eq!(xor_result.size(), 4) // {1, 2, 5, 6}
  assert_eq!(xor_result.contains(1U), true)
  assert_eq!(xor_result.contains(2U), true)
  assert_eq!(xor_result.contains(5U), true)
  assert_eq!(xor_result.contains(6U), true)

  // 交集部分应该不存在
  assert_eq!(xor_result.contains(3U), false)
  assert_eq!(xor_result.contains(4U), false)

  // 测试与空集合的XOR
  let empty = @RoaringBitmap.new()
  let xor_with_empty = bitmap1.xor(empty)
  assert_eq!(xor_with_empty.equals(bitmap1), true)

  // 测试相同集合的XOR
  let xor_self = bitmap1.xor(bitmap1)
  assert_eq!(xor_self.is_empty(), true)
}

///| 测试批量添加
test "test_add_many" {
  let bitmap = @RoaringBitmap.new()
  let values = [1U, 3U, 5U, 7U, 9U, 100U, 200U, 65536U, 65537U]
  let result = bitmap.add_many(values)
  assert_eq!(result.size(), 9)
  for i = 0; i < values.length(); i = i + 1 {
    assert_eq!(result.contains(values[i]), true)
  }

  // 测试重复元素的批量添加
  let values_with_dups = [1U, 1U, 2U, 2U, 3U, 3U]
  let result2 = bitmap.add_many(values_with_dups)
  assert_eq!(result2.size(), 3) // 应该去重

  // 测试空数组的批量添加
  let empty_values = []
  let result3 = bitmap.add_many(empty_values)
  assert_eq!(result3.equals(bitmap), true)

  // 测试大量数据的批量添加
  let large_values = []
  for i = 0; i < 1000; i = i + 1 {
    large_values.push((i * 2).reinterpret_as_uint())
  }
  let large_result = bitmap.add_many(large_values)
  assert_eq!(large_result.size(), 1000)
}

///| 测试迭代器功能
test "test_iter" {
  let bitmap = @RoaringBitmap.from_array([1U, 3U, 5U, 7U, 9U])
  let collected = []
  bitmap.iter(fn(value) { collected.push(value) })
  assert_eq!(collected.length(), 5)
  assert_eq!(collected[0], 1U)
  assert_eq!(collected[1], 3U)
  assert_eq!(collected[2], 5U)
  assert_eq!(collected[3], 7U)
  assert_eq!(collected[4], 9U)

  // 测试空bitmap的迭代
  let empty = @RoaringBitmap.new()
  let empty_collected = []
  empty.iter(fn(value) { empty_collected.push(value) })
  assert_eq!(empty_collected.length(), 0)
}

///| 测试范围查询
test "test_range" {
  let bitmap = @RoaringBitmap.from_array([1U, 5U, 10U, 15U, 20U, 25U, 30U])

  // 测试完全包含的范围
  let range1 = bitmap.range(5U, 20U)
  assert_eq!(range1.size(), 4) // {5, 10, 15, 20}
  assert_eq!(range1.contains(5U), true)
  assert_eq!(range1.contains(10U), true)
  assert_eq!(range1.contains(15U), true)
  assert_eq!(range1.contains(20U), true)
  assert_eq!(range1.contains(1U), false)
  assert_eq!(range1.contains(25U), false)

  // 测试部分重叠的范围
  let range2 = bitmap.range(0U, 8U)
  assert_eq!(range2.size(), 2) // {1, 5}

  // 测试完全不重叠的范围
  let range3 = bitmap.range(35U, 40U)
  assert_eq!(range3.is_empty(), true)

  // 测试单点范围
  let range4 = bitmap.range(15U, 15U)
  assert_eq!(range4.size(), 1)
  assert_eq!(range4.contains(15U), true)
}

///| 测试Jaccard相似度
test "test_jaccard_similarity" {
  let bitmap1 = @RoaringBitmap.from_array([1U, 2U, 3U, 4U])
  let bitmap2 = @RoaringBitmap.from_array([3U, 4U, 5U, 6U])

  // 交集大小: 2 {3, 4}
  // 并集大小: 6 {1, 2, 3, 4, 5, 6}
  // Jaccard = 2/6 = 0.333...
  let similarity = bitmap1.jaccard_similarity(bitmap2)
  assert_eq!(similarity > 0.33 && similarity < 0.34, true)

  // 测试相同bitmap的相似度
  let similarity_self = bitmap1.jaccard_similarity(bitmap1)
  assert_eq!(similarity_self, 1.0)

  // 测试完全不相交bitmap的相似度
  let bitmap3 = @RoaringBitmap.from_array([10U, 20U, 30U])
  let similarity_disjoint = bitmap1.jaccard_similarity(bitmap3)
  assert_eq!(similarity_disjoint, 0.0)

  // 测试与空bitmap的相似度
  let empty = @RoaringBitmap.new()
  let similarity_empty = bitmap1.jaccard_similarity(empty)
  assert_eq!(similarity_empty, 0.0)

  // 测试两个空bitmap的相似度
  let similarity_both_empty = empty.jaccard_similarity(empty)
  assert_eq!(similarity_both_empty, 1.0)
}

///| 测试容器转换和优化
test "test_container_conversion" {
  // 测试数组容器到位图容器的转换
  let mut bitmap = @RoaringBitmap.new()

  // 添加足够多的元素触发转换
  for i = 0; i < 5000; i = i + 1 {
    bitmap = bitmap.add(i.reinterpret_as_uint())
  }
  let stats = bitmap.get_stats()
  assert_eq!(stats.bitmap_containers > 0, true)

  // 移除大部分元素，可能触发回转为数组容器
  for i = 1000; i < 5000; i = i + 1 {
    bitmap = bitmap.remove(i.reinterpret_as_uint())
  }
  assert_eq!(bitmap.size(), 1000)

  // 验证剩余元素的正确性
  for i = 0; i < 1000; i = i + 1 {
    assert_eq!(bitmap.contains(i.reinterpret_as_uint()), true)
  }
}

///| 测试运行长度编码容器
test "test_run_length_encoding" {
  // 创建连续数据，适合运行长度编码
  let consecutive_values = []
  for i = 1000; i < 2000; i = i + 1 {
    consecutive_values.push(i.reinterpret_as_uint())
  }
  let bitmap = @RoaringBitmap.from_array(consecutive_values)
  assert_eq!(bitmap.size(), 1000)

  // 验证连续性
  assert_eq!(bitmap.contains(1000U), true)
  assert_eq!(bitmap.contains(1500U), true)
  assert_eq!(bitmap.contains(1999U), true)
  assert_eq!(bitmap.contains(999U), false)
  assert_eq!(bitmap.contains(2000U), false)

  // 测试运行容器的集合操作
  let other_consecutive = []
  for i = 1500; i < 2500; i = i + 1 {
    other_consecutive.push(i.reinterpret_as_uint())
  }
  let bitmap2 = @RoaringBitmap.from_array(other_consecutive)
  let union_result = bitmap.union(bitmap2)
  assert_eq!(union_result.size(), 1500) // 1000 to 2499
  let intersect_result = bitmap.intersect(bitmap2)
  assert_eq!(intersect_result.size(), 500) // 1500 to 1999
}

///| 测试复合集合操作
test "test_complex_set_operations" {
  let bitmap1 = @RoaringBitmap.from_array([1U, 2U, 3U, 4U, 5U])
  let bitmap2 = @RoaringBitmap.from_array([4U, 5U, 6U, 7U, 8U])
  let bitmap3 = @RoaringBitmap.from_array([1U, 3U, 5U, 7U, 9U])

  // 测试 (A ∪ B) ∩ C
  let union_ab = bitmap1.union(bitmap2)
  let result1 = union_ab.intersect(bitmap3)
  assert_eq!(result1.size(), 4) // {1, 3, 5, 7}

  // 测试 A - (B ∩ C)
  let intersect_bc = bitmap2.intersect(bitmap3)
  let result2 = bitmap1.difference(intersect_bc)
  assert_eq!(result2.size(), 4) // {1, 2, 3, 4}

  // 测试 (A ⊕ B) ∪ C (XOR then union)
  let xor_ab = bitmap1.xor(bitmap2)
  let result3 = xor_ab.union(bitmap3)
  assert_eq!(result3.size(), 8) // {1, 2, 3, 5, 6, 7, 8, 9}

  // 测试多重差集 A - B - C
  let diff1 = bitmap1.difference(bitmap2)
  let result4 = diff1.difference(bitmap3)
  assert_eq!(result4.size(), 1) // {2}
  assert_eq!(result4.contains(2U), true)
}

///| 测试边界和错误情况
test "test_edge_cases_extended" {
  // 测试最大值
  let max_value = 4294967295U
  let bitmap = @RoaringBitmap.singleton(max_value)
  assert_eq!(bitmap.contains(max_value), true)
  assert_eq!(bitmap.min(), Some(max_value))
  assert_eq!(bitmap.max(), Some(max_value))

  // 测试0值
  let zero_bitmap = @RoaringBitmap.singleton(0U)
  assert_eq!(zero_bitmap.contains(0U), true)
  assert_eq!(zero_bitmap.min(), Some(0U))
  assert_eq!(zero_bitmap.max(), Some(0U))

  // 测试极端稀疏数据
  let sparse_values = [0U, 1000000U, 2000000U, 3000000U, 4294967295U]
  let sparse_bitmap = @RoaringBitmap.from_array(sparse_values)
  assert_eq!(sparse_bitmap.size(), 5)
  for i = 0; i < sparse_values.length(); i = i + 1 {
    assert_eq!(sparse_bitmap.contains(sparse_values[i]), true)
  }

  // 测试大范围查询
  let full_range = sparse_bitmap.range(0U, 4294967295U)
  assert_eq!(full_range.equals(sparse_bitmap), true)
}

///| 测试批量操作性能
test "test_bulk_operations_performance" {
  // 创建两个大的bitmap
  let values1 = []
  let values2 = []
  for i = 0; i < 1000; i = i + 1 {
    values1.push((i * 2).reinterpret_as_uint()) // 偶数
    values2.push((i * 2 + 1).reinterpret_as_uint()) // 奇数
  }
  let bitmap1 = @RoaringBitmap.new().add_many(values1)
  let bitmap2 = @RoaringBitmap.new().add_many(values2)
  assert_eq!(bitmap1.size(), 1000)
  assert_eq!(bitmap2.size(), 1000)

  // 测试大集合的操作
  let union_result = bitmap1.union(bitmap2)
  assert_eq!(union_result.size(), 2000)
  let intersect_result = bitmap1.intersect(bitmap2)
  assert_eq!(intersect_result.is_empty(), true) // 偶数和奇数无交集
  let xor_result = bitmap1.xor(bitmap2)
  assert_eq!(xor_result.equals(union_result), true) // 无交集时XOR等于并集

  // 测试子集关系
  let subset_values = []
  for i = 0; i < 500; i = i + 1 {
    subset_values.push((i * 4).reinterpret_as_uint()) // 4的倍数
  }
  let subset_bitmap = @RoaringBitmap.new().add_many(subset_values)
  assert_eq!(subset_bitmap.is_subset(bitmap1), true) // 4的倍数是偶数的子集
  assert_eq!(subset_bitmap.is_subset(bitmap2), false) // 4的倍数不是奇数的子集
}

///| 测试统计信息的准确性
test "test_statistics_accuracy" {
  // 测试不同类型容器的统计
  let array_bitmap = @RoaringBitmap.from_array([1U, 3U, 5U, 7U, 9U])
  let array_stats = array_bitmap.get_stats()
  assert_eq!(array_stats.array_containers > 0, true)
  assert_eq!(array_stats.bitmap_containers, 0)

  // 创建位图容器
  let dense_values = []
  for i = 0; i < 5000; i = i + 1 {
    dense_values.push(i.reinterpret_as_uint())
  }
  let bitmap_container = @RoaringBitmap.from_array(dense_values)
  let bitmap_stats = bitmap_container.get_stats()
  assert_eq!(bitmap_stats.bitmap_containers > 0, true)

  // 验证总字节数合理性
  assert_eq!(bitmap_stats.total_bytes > 0, true)
  assert_eq!(bitmap_stats.compression_ratio > 0.0, true)

  // 验证容器总数
  assert_eq!(
    bitmap_stats.total_containers,
    bitmap_stats.array_containers +
    bitmap_stats.bitmap_containers +
    bitmap_stats.run_containers,
  )
}

///| 测试空操作的正确性
test "test_empty_operations_extended" {
  let empty = @RoaringBitmap.new()
  let non_empty = @RoaringBitmap.from_array([1U, 2U, 3U])

  // 测试所有操作与空集合的行为
  assert_eq!(empty.union(non_empty).equals(non_empty), true)
  assert_eq!(non_empty.union(empty).equals(non_empty), true)
  assert_eq!(empty.intersect(non_empty).is_empty(), true)
  assert_eq!(non_empty.intersect(empty).is_empty(), true)
  assert_eq!(empty.difference(non_empty).is_empty(), true)
  assert_eq!(non_empty.difference(empty).equals(non_empty), true)
  assert_eq!(empty.xor(non_empty).equals(non_empty), true)
  assert_eq!(non_empty.xor(empty).equals(non_empty), true)

  // 子集关系
  assert_eq!(empty.is_subset(non_empty), true)
  assert_eq!(empty.is_subset(empty), true)
  assert_eq!(non_empty.is_subset(empty), false)

  // 相似度
  assert_eq!(empty.jaccard_similarity(non_empty), 0.0)
  assert_eq!(empty.jaccard_similarity(empty), 1.0)

  // 范围查询
  assert_eq!(empty.range(0U, 1000U).is_empty(), true)
}
