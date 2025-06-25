# RoaringBitmap

[English](https://github.com/kesmeey/RoaringBitmap/blob/main/README.md) | [简体中文](https://github.com/kesmeey/RoaringBitmap/blob/master/README_zh_CN.md)


A high-performance RoaringBitmap implementation in MoonBit, a compressed bitmap data structure designed for large sparse integer sets. RoaringBitmap provides excellent compression ratios while maintaining fast operations, widely used in databases, search engines, and analytics systems.

## 🚀 Core Features

• 📦 **Smart Compression** – Automatically selects optimal container types based on data density  
• ⚡ **High-Speed Operations** – Insert, delete, and query operations with near O(1) time complexity  
• 🔧 **Dynamic Optimization** – Automatically converts between array, bitmap, and run-length encoded containers  
• 📊 **Memory Efficient** – Saves up to 90% memory compared to traditional bitmaps  
• 🎯 **Set Operations** – Supports complete set operations including union, intersection, difference, and XOR  
• 🔄 **Batch Operations** – Efficient batch insertion and operations, suitable for big data processing  
• 📈 **Scalability** – Supports 32-bit unsigned integer range (0 to 4,294,967,295)  
• 🔍 **Rich Queries** – Provides advanced features like min/max queries, range queries, and rank queries  
• 📊 **Statistical Analysis** – Detailed memory usage and performance statistics

## 📥 Installation
```bash
moon add kesmeey/RoaringBitmap
```

## 🚀 Usage Guide

### 🔨 Creating RoaringBitmap
Multiple ways to create and initialize RoaringBitmap.

```moonbit
// Create empty bitmap
  let bitmap = @RoaringBitmap.new()

// Create from single value
  let single = @RoaringBitmap.singleton(42U)

// Create from array
  let values = [1U, 3U, 5U, 7U, 9U, 100U, 1000U]
  let bitmap = @RoaringBitmap.from_array(values)
```

### ➕ Adding and Removing Elements
Use `add()` and `remove()` methods to manipulate set elements.

```moonbit
  let mut bitmap = @RoaringBitmap.new()

  // Add single elements
  bitmap = bitmap.add(10U)
  bitmap = bitmap.add(20U)
  bitmap = bitmap.add(30U)

  // Batch add (high performance)
  let new_values = [100U, 200U, 300U, 65536U, 131072U]
  bitmap = bitmap.add_many(new_values)

  // Remove element
  bitmap = bitmap.remove(20U)

  println("Current size: \{bitmap.size()}")  // Output element count
```

### 🔍 Query Operations
Check element existence and get set information.

```moonbit
  let bitmap = @RoaringBitmap.from_array([1U, 10U, 100U, 1000U, 10000U])

  // Check if element exists
  if bitmap.contains(100U) {
    println("100 exists in the set")
  }

  // Get minimum and maximum values
  match bitmap.min() {
    Some(min_val) => println("Minimum: \{min_val}")
    None => println("Set is empty")
  }

  match bitmap.max() {
    Some(max_val) => println("Maximum: \{max_val}")
    None => println("Set is empty")
  }

  // Basic information
  println("Set size: \{bitmap.size()}")
  println("Is empty: \{bitmap.is_empty()}")
```

### 🎯 Set Operations
Execute efficient set operations with complete set algebra support.

```moonbit
  let set1 = @RoaringBitmap.from_array([1U, 2U, 3U, 4U, 5U])
  let set2 = @RoaringBitmap.from_array([4U, 5U, 6U, 7U, 8U])

  // Union (A ∪ B)
  let union_result = set1.union(set2)
  println("Union size: \{union_result.size()}")  // 8 elements

  // Intersection (A ∩ B)
  let intersect_result = set1.intersect(set2)
  println("Intersection size: \{intersect_result.size()}")  // 2 elements {4, 5}

  // Difference (A - B)
  let diff_result = set1.difference(set2)
  println("Difference size: \{diff_result.size()}")  // 3 elements {1, 2, 3}

  // Symmetric difference / XOR (A ⊕ B)
  let xor_result = set1.xor(set2)
  println("XOR size: \{xor_result.size()}")  // 6 elements {1, 2, 3, 6, 7, 8}
```

### 🔗 Set Relationship Checking
Check containment relationships and similarity between sets.

```moonbit
  let big_set = @RoaringBitmap.from_array([1U, 2U, 3U, 4U, 5U, 6U, 7U, 8U])
  let small_set = @RoaringBitmap.from_array([2U, 4U, 6U])
  let other_set = @RoaringBitmap.from_array([2U, 4U, 6U])

  // Subset check
  if small_set.is_subset(big_set) {
    println("small_set is a subset of big_set")
  }

  // Equality check
  if small_set.equals(other_set) {
    println("Two sets are equal")
  }

  // Jaccard similarity
  let similarity = big_set.jaccard_similarity(small_set)
  println("Jaccard similarity: \{similarity}")
```

### 🔍 Advanced Query Features
Range queries, iteration, and data conversion operations.

```moonbit
  let bitmap = @RoaringBitmap.from_array([1U, 5U, 10U, 15U, 20U, 25U, 30U, 100U])

  // Range query
  let range_result = bitmap.range(10U, 25U)
  println("Elements in range [10, 25]: \{range_result.size()}")

  // Iterate all elements
  println("All elements:")
  bitmap.iter(fn(value) {
    println("  \{value}")
  })

  // Convert to array
  let array = bitmap.to_array()
  println("Convert to array: \{array}")

  // Clear set
  let cleared = bitmap.clear()
  assert_true!(cleared.is_empty())
```

### 📊 Performance Statistics and Debugging
Get detailed memory usage and performance information.

```moonbit
  // Create bitmaps with different data types
  let sparse_data = [1U, 100U, 1000U, 10000U]  // Sparse data -> Array container
  let dense_data = []
  for i = 0; i < 5000; i = i + 1 {
    dense_data.push(i.reinterpret_as_uint())    // Dense data -> Bitmap container
  }

  let sparse_bitmap = @RoaringBitmap.from_array(sparse_data)
  let dense_bitmap = @RoaringBitmap.from_array(dense_data)

  // Get statistics
  let sparse_stats = sparse_bitmap.get_stats()
  println("Sparse data statistics:")
  println("  Total containers: \{sparse_stats.total_containers}")
  println("  Array containers: \{sparse_stats.array_containers}")
  println("  Bitmap containers: \{sparse_stats.bitmap_containers}")
  println("  Total bytes: \{sparse_stats.total_bytes}")
  println("  Compression ratio: \{sparse_stats.compression_ratio}")

  let dense_stats = dense_bitmap.get_stats()
  println("Dense data statistics:")
  println("  Total containers: \{dense_stats.total_containers}")
  println("  Bitmap containers: \{dense_stats.bitmap_containers}")
  println("  Compression ratio: \{dense_stats.compression_ratio}")
```

### 🔄 Large Dataset Processing
Handle large-scale data and cross-container operations.

```moonbit
  // Create large dataset
  let mut large_bitmap = @RoaringBitmap.new()

  // Add data across multiple 16-bit high positions
  let large_values = [
    1U,          // High 16 bits: 0
    65536U,      // High 16 bits: 1
    131072U,     // High 16 bits: 2
    196608U,     // High 16 bits: 3
    4294967295U  // High 16 bits: 65535 (maximum value)
  ]

  large_bitmap = large_bitmap.add_many(large_values)

  // Verify cross-container operations
  println("Cross-container bitmap size: \{large_bitmap.size()}")
  println("Minimum: \{large_bitmap.min()}")
  println("Maximum: \{large_bitmap.max()}")

  // Create consecutive data (suitable for run-length encoding)
  let consecutive = []
  for i = 10000; i < 15000; i = i + 1 {
    consecutive.push(i.reinterpret_as_uint())
  }
  let rle_bitmap = @RoaringBitmap.from_array(consecutive)
  let rle_stats = rle_bitmap.get_stats()
  println("RLE data compression ratio: \{rle_stats.compression_ratio}")
```

### 🎛️ Complex Set Operations
Combine multiple set operations for complex queries.

```moonbit
  let set_a = @RoaringBitmap.from_array([1U, 2U, 3U, 4U, 5U])
  let set_b = @RoaringBitmap.from_array([4U, 5U, 6U, 7U, 8U])
  let set_c = @RoaringBitmap.from_array([1U, 3U, 5U, 7U, 9U])

  // Complex query: (A ∪ B) ∩ C
  let union_ab = set_a.union(set_b)        // {1,2,3,4,5,6,7,8}
  let result1 = union_ab.intersect(set_c)  // {1,3,5,7}
  println("(A ∪ B) ∩ C result size: \{result1.size()}")

  // Complex query: A - (B ∩ C)
  let intersect_bc = set_b.intersect(set_c)  // {5,7}
  let result2 = set_a.difference(intersect_bc)  // {1,2,3,4}
  println("A - (B ∩ C) result size: \{result2.size()}")

  // Ternary XOR: A ⊕ B ⊕ C
  let xor_ab = set_a.xor(set_b)
  let result3 = xor_ab.xor(set_c)
  println("A ⊕ B ⊕ C result size: \{result3.size()}")
```

## 📊 Performance Characteristics

| Operation | Time Complexity | Space Complexity | Description |
|-----------|----------------|------------------|-------------|
| `new()` | O(1) | O(1) | Create empty bitmap |
| `add()` | O(1) | O(1) | Add single element |
| `remove()` | O(1) | O(1) | Remove single element |
| `contains()` | O(1) | O(1) | Query element existence |
| `union()` | O(n+m) | O(n+m) | Union of two bitmaps |
| `intersect()` | O(min(n,m)) | O(min(n,m)) | Intersection of two bitmaps |
| `add_many()` | O(k log k) | O(k) | Batch add k elements |
| `range()` | O(output) | O(output) | Range query |
| `to_array()` | O(n) | O(n) | Convert to array |

Where:
- `n`, `m` = Number of elements in two bitmaps
- `k` = Number of elements in batch operation

## 🏗️ Implementation Details

RoaringBitmap uses three container types for automatic storage optimization:

### 📦 Container Types

1. **Array Container (ArrayContainer)**
   - **Usage**: Sparse data (< 4096 elements)
   - **Storage**: Sorted `UInt16` array
   - **Advantages**: High memory efficiency, fast queries

2. **Bitmap Container (BitmapContainer)**  
   - **Usage**: Dense data (≥ 4096 elements)
   - **Storage**: 1024 `UInt64` word bitmap
   - **Advantages**: Extremely fast set operations

3. **Run-Length Encoded Container (RunContainer)**
   - **Usage**: Consecutive data segments
   - **Storage**: Array of (start position, length) pairs
   - **Advantages**: Extremely high compression ratio for consecutive data

### 🔄 Automatic Optimization

RoaringBitmap automatically selects optimal containers based on data characteristics:

```moonbit
  // Sparse data -> Array container
  let sparse = @RoaringBitmap.from_array([1U, 100U, 1000U])

  // Dense data -> Bitmap container  
  let dense_values = []
  for i = 0; i < 5000; i = i + 1 {
    dense_values.push(i.reinterpret_as_uint())
  }
  let dense = @RoaringBitmap.from_array(dense_values)

  // Consecutive data -> Run-length encoded container
  let consecutive_values = []
  for i = 10000; i < 15000; i = i + 1 {
    consecutive_values.push(i.reinterpret_as_uint())
  }
  let consecutive = @RoaringBitmap.from_array(consecutive_values)
```

### 📈 Container Conversion Thresholds

- **Array → Bitmap**: Element count ≥ 4096
- **Bitmap → Array**: Element count < 4096  
- **Run-Length Encoding**: Used when the number of consecutive segments is significantly less than total elements

## 🎯 Use Cases

### 💾 Database Indexing
```moonbit
  // User ID sets
  let active_users = @RoaringBitmap.from_array([1001U, 1005U, 1010U, 1015U])
  let premium_users = @RoaringBitmap.from_array([1005U, 1010U, 1020U, 1025U])

  // Active premium users
  let active_premium = active_users.intersect(premium_users)
  println("Active premium users: \{active_premium.size()}")
```

### 🔍 Search Engines
```moonbit
  // Document ID sets
  let keyword1_docs = @RoaringBitmap.from_array([1U, 5U, 10U, 15U])
  let keyword2_docs = @RoaringBitmap.from_array([3U, 5U, 15U, 20U])

  // Documents containing both keywords
  let both_keywords = keyword1_docs.intersect(keyword2_docs)
  let results = both_keywords.to_array()
  println("Search result document IDs: \{results}")
```

### 📊 Data Analytics
```moonbit
  // Time series data points
  let mut morning_events = @RoaringBitmap.new()
  let afternoon_events = @RoaringBitmap.new()

  // Add event timestamps
  for hour = 6; hour < 12; hour = hour + 1 {
    for minute = 0; minute < 60; minute = minute + 5 {
      let timestamp = (hour * 3600 + minute * 60).reinterpret_as_uint()
      morning_events = morning_events.add(timestamp)
    }
  }

  println("Morning events: \{morning_events.size()}")
  let stats = morning_events.get_stats()
  println("Compression ratio: \{stats.compression_ratio}")
```

## 🔧 Configuration and Tuning

### Memory Usage Optimization
```moonbit
  // For scenarios with known large element counts, use batch operations
  let large_dataset = []
  for i = 0; i < 100000; i = i + 1 {
    large_dataset.push(i.reinterpret_as_uint())
  }

  // Recommended: Batch creation
  let bitmap = @RoaringBitmap.from_array(large_dataset)

  // Not recommended: Individual addition
  // let mut bitmap = @RoaringBitmap.new()
  // for value in large_dataset {
  //   bitmap = bitmap.add(value)
  // }
```

### Performance Monitoring
```moonbit
  let bitmap = @RoaringBitmap.from_array([/* data */]) //e.g. [1,2,3]
  let stats = bitmap.get_stats()

  // Monitor compression effectiveness
  if stats.compression_ratio > 2.0 {
    println("Good compression effect")
  } else {
    println("Consider if data structure is suitable")
  }

  // Monitor container distribution
  println("Container distribution:")
  println("  Array containers: \{stats.array_containers}")
  println("  Bitmap containers: \{stats.bitmap_containers}")  
  println("  Run containers: \{stats.run_containers}")
```

## 🆚 RoaringBitmap vs Traditional Bitmap

| Feature | Traditional Bitmap | RoaringBitmap |
|---------|-------------------|---------------|
| **Sparse Data** | Low efficiency | Highly optimized |
| **Dense Data** | High efficiency | Equally efficient |
| **Set Operations** | Fast | Equally fast |
| **Compression** | No compression | Smart compression |
| **Use Cases** | Dense data | General purpose |

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork this repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📜 License

This project is licensed under the Apache-2.0 License. See the LICENSE file for details.

## 🔗 Related Resources

- [RoaringBitmap Official Website](https://roaringbitmap.org/)
- [MoonBit Language Documentation](https://www.moonbitlang.com/docs/)
- [RoaringBitmap Implementation Reference](https://github.com/RoaringBitmap/RoaringBitmap)
