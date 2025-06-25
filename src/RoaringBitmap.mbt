///| 创建空的 RoaringBitmap
pub fn new() -> RoaringBitmap {
  RoaringBitmap::{ containers: [], size: 0 }
}

///| 从单个值创建 RoaringBitmap
pub fn singleton(value : UInt) -> RoaringBitmap {
  let high = extract_high_16(value)
  let low = extract_low_16(value)
  let container = ArrayContainer([low])
  let high_container = HighContainer::{ key: high, container, cardinality: 1 }
  RoaringBitmap::{ containers: [high_container], size: 1 }
}

///| 从数组创建 RoaringBitmap
pub fn from_array(values : Array[UInt]) -> RoaringBitmap {
  let mut bitmap = new()
  for i = 0; i < values.length(); i = i + 1 {
    bitmap = bitmap.add(values[i])
  }
  bitmap
}

///| 添加单个元素
pub fn add(self : RoaringBitmap, value : UInt) -> RoaringBitmap {
  let high = extract_high_16(value)
  let low = extract_low_16(value)

  // 查找对应的容器
  match find_container_index(self.containers, high) {
    Found(index) => {
      // 容器存在，添加到现有容器
      let container = self.containers[index]
      if container_contains(container.container, low) {
        // 元素已存在，返回原bitmap
        self
      } else {
        // 添加元素到容器
        let new_container = container_add(container.container, low)
        let new_high_container = HighContainer::{
          key: container.key,
          container: new_container,
          cardinality: container.cardinality + 1,
        }
        let new_containers = array_replace_at(
          self.containers,
          index,
          new_high_container,
        )
        RoaringBitmap::{ containers: new_containers, size: self.size + 1 }
      }
    }
    NotFound(insert_pos) => {
      // 容器不存在，创建新容器
      let new_container = ArrayContainer([low])
      let new_high_container = HighContainer::{
        key: high,
        container: new_container,
        cardinality: 1,
      }
      let new_containers = array_insert_at(
        self.containers,
        insert_pos,
        new_high_container,
      )
      RoaringBitmap::{ containers: new_containers, size: self.size + 1 }
    }
  }
}

///| 移除单个元素
pub fn remove(self : RoaringBitmap, value : UInt) -> RoaringBitmap {
  let high = extract_high_16(value)
  let low = extract_low_16(value)
  match find_container_index(self.containers, high) {
    Found(index) => {
      let container = self.containers[index]
      if container_contains(container.container, low) {
        let new_container = container_remove(container.container, low)
        let new_cardinality = container.cardinality - 1
        if new_cardinality == 0 {
          // 容器为空，移除整个容器
          let new_containers = array_remove_at(self.containers, index)
          RoaringBitmap::{ containers: new_containers, size: self.size - 1 }
        } else {
          // 更新容器
          let new_high_container = HighContainer::{
            key: container.key,
            container: new_container,
            cardinality: new_cardinality,
          }
          let new_containers = array_replace_at(
            self.containers,
            index,
            new_high_container,
          )
          RoaringBitmap::{ containers: new_containers, size: self.size - 1 }
        }
      } else {
        // 元素不存在，返回原bitmap
        self
      }
    }
    NotFound(_) =>
      // 容器不存在，元素不存在，返回原bitmap
      return self
  }
}

///| 检查元素是否存在
pub fn contains(self : RoaringBitmap, value : UInt) -> Bool {
  let high = extract_high_16(value)
  let low = extract_low_16(value)
  match find_container_index(self.containers, high) {
    Found(index) => {
      let container = self.containers[index]
      container_contains(container.container, low)
    }
    NotFound(_) => false
  }
}

///| 获取bitmap的大小（元素个数）
pub fn size(self : RoaringBitmap) -> Int {
  self.size
}

///| 检查bitmap是否为空
pub fn is_empty(self : RoaringBitmap) -> Bool {
  self.size == 0
}

///| 清空bitmap
pub fn clear(self : RoaringBitmap) -> RoaringBitmap {
  self.containers.clear()
  self.size = 0
  self
}

///| 转换为数组
pub fn to_array(self : RoaringBitmap) -> Array[UInt] {
  let result = []
  for i = 0; i < self.containers.length(); i = i + 1 {
    let container = self.containers[i]
    let high_bits = container.key.to_int().reinterpret_as_uint() << 16
    let low_values = container_to_array(container.container)
    for j = 0; j < low_values.length(); j = j + 1 {
      result.push(high_bits | low_values[j].to_int().reinterpret_as_uint())
    }
  }
  result
}

///| 并集操作
pub fn union(self : RoaringBitmap, other : RoaringBitmap) -> RoaringBitmap {
  if self.is_empty() {
    return other
  }
  if other.is_empty() {
    return self
  }
  let result_containers = []
  let mut i = 0
  let mut j = 0
  let mut total_size = 0
  while i < self.containers.length() && j < other.containers.length() {
    let container1 = self.containers[i]
    let container2 = other.containers[j]
    if container1.key < container2.key {
      result_containers.push(container1)
      total_size = total_size + container1.cardinality
      i = i + 1
    } else if container1.key > container2.key {
      result_containers.push(container2)
      total_size = total_size + container2.cardinality
      j = j + 1
    } else {
      // 相同key，需要合并容器
      let merged_container = container_union(
        container1.container,
        container2.container,
      )
      let merged_cardinality = container_cardinality(merged_container)
      let merged_high_container = HighContainer::{
        key: container1.key,
        container: merged_container,
        cardinality: merged_cardinality,
      }
      result_containers.push(merged_high_container)
      total_size = total_size + merged_cardinality
      i = i + 1
      j = j + 1
    }
  }

  // 添加剩余的容器
  while i < self.containers.length() {
    let container = self.containers[i]
    result_containers.push(container)
    total_size = total_size + container.cardinality
    i = i + 1
  }
  while j < other.containers.length() {
    let container = other.containers[j]
    result_containers.push(container)
    total_size = total_size + container.cardinality
    j = j + 1
  }
  RoaringBitmap::{ containers: result_containers, size: total_size }
}

///| 交集操作
pub fn intersect(self : RoaringBitmap, other : RoaringBitmap) -> RoaringBitmap {
  if self.is_empty() || other.is_empty() {
    return new()
  }
  let result_containers = []
  let mut i = 0
  let mut j = 0
  let mut total_size = 0
  while i < self.containers.length() && j < other.containers.length() {
    let container1 = self.containers[i]
    let container2 = other.containers[j]
    if container1.key < container2.key {
      i = i + 1
    } else if container1.key > container2.key {
      j = j + 1
    } else {
      // 相同key，计算交集
      let intersect_container = container_intersect(
        container1.container,
        container2.container,
      )
      let intersect_cardinality = container_cardinality(intersect_container)
      if intersect_cardinality > 0 {
        let intersect_high_container = HighContainer::{
          key: container1.key,
          container: intersect_container,
          cardinality: intersect_cardinality,
        }
        result_containers.push(intersect_high_container)
        total_size = total_size + intersect_cardinality
      }
      i = i + 1
      j = j + 1
    }
  }
  RoaringBitmap::{ containers: result_containers, size: total_size }
}

///| 差集操作 (self - other)
pub fn difference(self : RoaringBitmap, other : RoaringBitmap) -> RoaringBitmap {
  if self.is_empty() || other.is_empty() {
    return self
  }
  let result_containers = []
  let mut i = 0
  let mut j = 0
  let mut total_size = 0
  while i < self.containers.length() && j < other.containers.length() {
    let container1 = self.containers[i]
    let container2 = other.containers[j]
    if container1.key < container2.key {
      result_containers.push(container1)
      total_size = total_size + container1.cardinality
      i = i + 1
    } else if container1.key > container2.key {
      j = j + 1
    } else {
      // 相同key，计算差集
      let diff_container = container_difference(
        container1.container,
        container2.container,
      )
      let diff_cardinality = container_cardinality(diff_container)
      if diff_cardinality > 0 {
        let diff_high_container = HighContainer::{
          key: container1.key,
          container: diff_container,
          cardinality: diff_cardinality,
        }
        result_containers.push(diff_high_container)
        total_size = total_size + diff_cardinality
      }
      i = i + 1
      j = j + 1
    }
  }

  // 添加剩余的容器
  while i < self.containers.length() {
    let container = self.containers[i]
    result_containers.push(container)
    total_size = total_size + container.cardinality
    i = i + 1
  }
  RoaringBitmap::{ containers: result_containers, size: total_size }
}

///| 获取统计信息
pub fn get_stats(self : RoaringBitmap) -> RoaringStats {
  let mut array_count = 0
  let mut bitmap_count = 0
  let mut run_count = 0
  let mut total_bytes = 0
  for i = 0; i < self.containers.length(); i = i + 1 {
    let container = self.containers[i].container
    match container {
      ArrayContainer(arr) => {
        array_count = array_count + 1
        total_bytes = total_bytes + arr.length() * 2 // 每个UInt16占2字节
      }
      BitmapContainer(_) => {
        bitmap_count = bitmap_count + 1
        total_bytes = total_bytes + BITMAP_CONTAINER_SIZE
      }
      RunContainer(runs) => {
        run_count = run_count + 1
        total_bytes = total_bytes + runs.length() * 4 // 每个Run占4字节
      }
    }
  }
  let original_size = if self.size == 0 { 1 } else { (self.size + 7) / 8 } // 避免除零
  let compression_ratio = total_bytes.to_double() / original_size.to_double()
  RoaringStats::{
    total_containers: self.containers.length(),
    array_containers: array_count,
    bitmap_containers: bitmap_count,
    run_containers: run_count,
    total_bytes,
    compression_ratio,
  }
}

// =============== 辅助函数 ===============

///| 提取32位整数的高16位
fn extract_high_16(value : UInt) -> UInt16 {
  (value >> 16).reinterpret_as_int().to_uint16()
}

///| 提取32位整数的低16位
fn extract_low_16(value : UInt) -> UInt16 {
  let low_bits = value % 65536U // 2^16 = 65536
  low_bits.reinterpret_as_int().to_uint16()
}

///| 在排序数组中查找容器索引
fn find_container_index(
  containers : Array[HighContainer],
  key : UInt16
) -> SearchResult {
  let mut left = 0
  let mut right = containers.length()
  while left < right {
    let mid = (left + right) / 2
    let mid_key = containers[mid].key
    if mid_key == key {
      return Found(mid)
    } else if mid_key < key {
      left = mid + 1
    } else {
      right = mid
    }
  }
  NotFound(left)
}

///| 在指定位置插入元素到数组
fn array_insert_at[T](arr : Array[T], index : Int, element : T) -> Array[T] {
  let result = []
  for i = 0; i < index; i = i + 1 {
    result.push(arr[i])
  }
  result.push(element)
  for i = index; i < arr.length(); i = i + 1 {
    result.push(arr[i])
  }
  result
}

///| 替换数组中指定位置的元素
fn array_replace_at[T](arr : Array[T], index : Int, element : T) -> Array[T] {
  let result = []
  for i = 0; i < arr.length(); i = i + 1 {
    if i == index {
      result.push(element)
    } else {
      result.push(arr[i])
    }
  }
  result
}

///| 移除数组中指定位置的元素
fn array_remove_at[T](arr : Array[T], index : Int) -> Array[T] {
  let result = []
  for i = 0; i < arr.length(); i = i + 1 {
    if i != index {
      result.push(arr[i])
    }
  }
  result
}

///| 检查容器是否包含指定值
fn container_contains(container : Container, value : UInt16) -> Bool {
  match container {
    ArrayContainer(arr) => array_container_contains(arr, value)
    BitmapContainer(bitmap) => bitmap_container_contains(bitmap, value)
    RunContainer(runs) => run_container_contains(runs, value)
  }
}

///| 向容器添加元素
fn container_add(container : Container, value : UInt16) -> Container {
  match container {
    ArrayContainer(arr) => {
      let new_arr = array_container_add(arr, value)
      // 检查是否需要转换为位图容器
      if new_arr.length() >= ARRAY_CONTAINER_MAX_SIZE {
        array_to_bitmap_container(new_arr)
      } else {
        ArrayContainer(new_arr)
      }
    }
    BitmapContainer(bitmap) =>
      BitmapContainer(bitmap_container_add(bitmap, value))
    RunContainer(runs) => {
      let new_runs = run_container_add(runs, value)
      RunContainer(new_runs)
    }
  }
}

///| 从容器移除元素
fn container_remove(container : Container, value : UInt16) -> Container {
  match container {
    ArrayContainer(arr) => ArrayContainer(array_container_remove(arr, value))
    BitmapContainer(bitmap) => {
      let new_bitmap = bitmap_container_remove(bitmap, value)
      let cardinality = bitmap_container_cardinality(new_bitmap)
      // 检查是否需要转换为数组容器
      if cardinality < ARRAY_CONTAINER_MAX_SIZE {
        bitmap_to_array_container(new_bitmap)
      } else {
        BitmapContainer(new_bitmap)
      }
    }
    RunContainer(runs) => RunContainer(run_container_remove(runs, value))
  }
}

///| 容器并集操作
fn container_union(container1 : Container, container2 : Container) -> Container {
  match (container1, container2) {
    (ArrayContainer(arr1), ArrayContainer(arr2)) => {
      let union_arr = array_container_union(arr1, arr2)
      if union_arr.length() >= ARRAY_CONTAINER_MAX_SIZE {
        array_to_bitmap_container(union_arr)
      } else {
        ArrayContainer(union_arr)
      }
    }
    (ArrayContainer(arr), BitmapContainer(bitmap)) =>
      BitmapContainer(bitmap_container_union_with_array(bitmap, arr))
    (BitmapContainer(bitmap), ArrayContainer(arr)) =>
      BitmapContainer(bitmap_container_union_with_array(bitmap, arr))
    (BitmapContainer(bitmap1), BitmapContainer(bitmap2)) =>
      BitmapContainer(bitmap_container_union(bitmap1, bitmap2))
    (RunContainer(runs1), RunContainer(runs2)) =>
      RunContainer(run_container_union(runs1, runs2))
    // 其他组合可以通过转换处理
    _ => container_union_generic(container1, container2)
  }
}

///| 容器交集操作
fn container_intersect(
  container1 : Container,
  container2 : Container
) -> Container {
  match (container1, container2) {
    (ArrayContainer(arr1), ArrayContainer(arr2)) =>
      ArrayContainer(array_container_intersect(arr1, arr2))
    (ArrayContainer(arr), BitmapContainer(bitmap)) =>
      ArrayContainer(array_container_intersect_with_bitmap(arr, bitmap))
    (BitmapContainer(bitmap), ArrayContainer(arr)) =>
      ArrayContainer(array_container_intersect_with_bitmap(arr, bitmap))
    (BitmapContainer(bitmap1), BitmapContainer(bitmap2)) => {
      let intersect_bitmap = bitmap_container_intersect(bitmap1, bitmap2)
      let cardinality = bitmap_container_cardinality(intersect_bitmap)
      if cardinality < ARRAY_CONTAINER_MAX_SIZE {
        bitmap_to_array_container(intersect_bitmap) // 修正：直接调用转换函数
      } else {
        BitmapContainer(intersect_bitmap)
      }
    }
    (RunContainer(runs1), RunContainer(runs2)) =>
      RunContainer(run_container_intersect(runs1, runs2))
    _ => container_intersect_generic(container1, container2)
  }
}

///| 容器差集操作
///| 容器差集操作
fn container_difference(
  container1 : Container,
  container2 : Container
) -> Container {
  match (container1, container2) {
    (ArrayContainer(arr1), ArrayContainer(arr2)) =>
      ArrayContainer(array_container_difference(arr1, arr2))
    (ArrayContainer(arr), BitmapContainer(bitmap)) =>
      ArrayContainer(array_container_difference_with_bitmap(arr, bitmap))
    (BitmapContainer(bitmap), ArrayContainer(arr)) => {
      let diff_bitmap = bitmap_container_difference_with_array(bitmap, arr)
      let cardinality = bitmap_container_cardinality(diff_bitmap)
      if cardinality < ARRAY_CONTAINER_MAX_SIZE {
        bitmap_to_array_container(diff_bitmap) // 修正：直接调用转换函数
      } else {
        BitmapContainer(diff_bitmap)
      }
    }
    (BitmapContainer(bitmap1), BitmapContainer(bitmap2)) => {
      let diff_bitmap = bitmap_container_difference(bitmap1, bitmap2)
      let cardinality = bitmap_container_cardinality(diff_bitmap)
      if cardinality < ARRAY_CONTAINER_MAX_SIZE {
        bitmap_to_array_container(diff_bitmap) // 修正：直接调用转换函数
      } else {
        BitmapContainer(diff_bitmap)
      }
    }
    (RunContainer(runs1), RunContainer(runs2)) =>
      RunContainer(run_container_difference(runs1, runs2))
    _ => container_difference_generic(container1, container2)
  }
}

///| 获取容器基数
fn container_cardinality(container : Container) -> Int {
  match container {
    ArrayContainer(arr) => arr.length()
    BitmapContainer(bitmap) => bitmap_container_cardinality(bitmap)
    RunContainer(runs) => run_container_cardinality(runs)
  }
}

///| 容器转换为数组
fn container_to_array(container : Container) -> Array[UInt16] {
  match container {
    ArrayContainer(arr) => arr
    BitmapContainer(bitmap) => bitmap_container_to_array(bitmap)
    RunContainer(runs) => run_container_to_array(runs)
  }
}

// =============== 数组容器操作 ===============

///| 数组容器包含检查
fn array_container_contains(arr : Array[UInt16], value : UInt16) -> Bool {
  binary_search_contains(arr, value)
}

///| 数组容器添加元素
fn array_container_add(arr : Array[UInt16], value : UInt16) -> Array[UInt16] {
  match binary_search(arr, value) {
    Found(_) => arr // 元素已存在
    NotFound(insert_pos) => array_insert_sorted(arr, insert_pos, value)
  }
}

///| 数组容器移除元素
fn array_container_remove(arr : Array[UInt16], value : UInt16) -> Array[UInt16] {
  match binary_search(arr, value) {
    Found(index) => array_remove_at_uint16(arr, index)
    NotFound(_) => arr // 元素不存在
  }
}

///| 数组容器并集
fn array_container_union(
  arr1 : Array[UInt16],
  arr2 : Array[UInt16]
) -> Array[UInt16] {
  let result = []
  let mut i = 0
  let mut j = 0
  while i < arr1.length() && j < arr2.length() {
    let val1 = arr1[i]
    let val2 = arr2[j]
    if val1 < val2 {
      result.push(val1)
      i = i + 1
    } else if val1 > val2 {
      result.push(val2)
      j = j + 1
    } else {
      result.push(val1) // 相等，只添加一次
      i = i + 1
      j = j + 1
    }
  }

  // 添加剩余元素
  while i < arr1.length() {
    result.push(arr1[i])
    i = i + 1
  }
  while j < arr2.length() {
    result.push(arr2[j])
    j = j + 1
  }
  result
}

///| 数组容器交集
fn array_container_intersect(
  arr1 : Array[UInt16],
  arr2 : Array[UInt16]
) -> Array[UInt16] {
  let result = []
  let mut i = 0
  let mut j = 0
  while i < arr1.length() && j < arr2.length() {
    let val1 = arr1[i]
    let val2 = arr2[j]
    if val1 < val2 {
      i = i + 1
    } else if val1 > val2 {
      j = j + 1
    } else {
      result.push(val1) // 相等，添加到结果
      i = i + 1
      j = j + 1
    }
  }
  result
}

///| 数组容器差集
fn array_container_difference(
  arr1 : Array[UInt16],
  arr2 : Array[UInt16]
) -> Array[UInt16] {
  let result = []
  let mut i = 0
  let mut j = 0
  while i < arr1.length() && j < arr2.length() {
    let val1 = arr1[i]
    let val2 = arr2[j]
    if val1 < val2 {
      result.push(val1) // val1 不在 arr2 中
      i = i + 1
    } else if val1 > val2 {
      j = j + 1
    } else {
      // 相等，跳过（从 arr1 中移除）
      i = i + 1
      j = j + 1
    }
  }

  // 添加 arr1 的剩余元素
  while i < arr1.length() {
    result.push(arr1[i])
    i = i + 1
  }
  result
}

// =============== 位图容器操作 ===============

///| 位图容器包含检查
fn bitmap_container_contains(
  bitmap : FixedArray[UInt64],
  value : UInt16
) -> Bool {
  let word_index = value.to_int() / 64
  let bit_index = value.to_int() % 64
  let word = bitmap[word_index]
  (word & (1UL << bit_index)) != 0UL
}

///| 位图容器添加元素
fn bitmap_container_add(
  bitmap : FixedArray[UInt64],
  value : UInt16
) -> FixedArray[UInt64] {
  let new_bitmap = FixedArray::make(1024, 0UL)
  for i = 0; i < 1024; i = i + 1 {
    new_bitmap[i] = bitmap[i]
  }
  let word_index = value.to_int() / 64
  let bit_index = value.to_int() % 64
  new_bitmap[word_index] = new_bitmap[word_index] | (1UL << bit_index)
  new_bitmap
}

///| 位图容器移除元素
fn bitmap_container_remove(
  bitmap : FixedArray[UInt64],
  value : UInt16
) -> FixedArray[UInt64] {
  let new_bitmap = FixedArray::make(1024, 0UL)
  for i = 0; i < 1024; i = i + 1 {
    new_bitmap[i] = bitmap[i]
  }
  let word_index = value.to_int() / 64
  let bit_index = value.to_int() % 64
  // Replace ~(1UL << bit_index) with (0xFFFFFFFFFFFFFFFFUL ^ (1UL << bit_index))
  new_bitmap[word_index] = new_bitmap[word_index] &
    (0xFFFFFFFFFFFFFFFFUL ^ (1UL << bit_index))
  new_bitmap
}

///| 位图容器并集
fn bitmap_container_union(
  bitmap1 : FixedArray[UInt64],
  bitmap2 : FixedArray[UInt64]
) -> FixedArray[UInt64] {
  let result = FixedArray::make(1024, 0UL)
  for i = 0; i < 1024; i = i + 1 {
    result[i] = bitmap1[i] | bitmap2[i]
  }
  result
}

///| 位图容器交集
fn bitmap_container_intersect(
  bitmap1 : FixedArray[UInt64],
  bitmap2 : FixedArray[UInt64]
) -> FixedArray[UInt64] {
  let result = FixedArray::make(1024, 0UL)
  for i = 0; i < 1024; i = i + 1 {
    result[i] = bitmap1[i] & bitmap2[i]
  }
  result
}

///| 位图容器差集
fn bitmap_container_difference(
  bitmap1 : FixedArray[UInt64],
  bitmap2 : FixedArray[UInt64]
) -> FixedArray[UInt64] {
  let result = FixedArray::make(1024, 0UL)
  for i = 0; i < 1024; i = i + 1 {
    // Replace ~bitmap2[i] with (0xFFFFFFFFFFFFFFFFUL ^ bitmap2[i])
    result[i] = bitmap1[i] & (0xFFFFFFFFFFFFFFFFUL ^ bitmap2[i])
  }
  result
}

///| 计算位图容器基数
fn bitmap_container_cardinality(bitmap : FixedArray[UInt64]) -> Int {
  let mut count = 0
  for i = 0; i < 1024; i = i + 1 {
    count = count + popcount(bitmap[i])
  }
  count
}

///| 位图容器转数组
fn bitmap_container_to_array(bitmap : FixedArray[UInt64]) -> Array[UInt16] {
  let result = []
  for word_index = 0; word_index < 1024; word_index = word_index + 1 {
    let word = bitmap[word_index]
    if word != 0UL {
      for bit_index = 0; bit_index < 64; bit_index = bit_index + 1 {
        if (word & (1UL << bit_index)) != 0UL {
          let value = word_index * 64 + bit_index
          result.push(value.to_uint16())
        }
      }
    }
  }
  result
}

// =============== 辅助函数 ===============

///| 二进制搜索
fn binary_search(arr : Array[UInt16], value : UInt16) -> SearchResult {
  let mut left = 0
  let mut right = arr.length()
  while left < right {
    let mid = (left + right) / 2
    let mid_val = arr[mid]
    if mid_val == value {
      return Found(mid)
    } else if mid_val < value {
      left = mid + 1
    } else {
      right = mid
    }
  }
  NotFound(left)
}

///| 二进制搜索包含检查
fn binary_search_contains(arr : Array[UInt16], value : UInt16) -> Bool {
  match binary_search(arr, value) {
    Found(_) => true
    NotFound(_) => false
  }
}

///| 在排序数组中插入元素
fn array_insert_sorted(
  arr : Array[UInt16],
  index : Int,
  value : UInt16
) -> Array[UInt16] {
  let result = []
  for i = 0; i < index; i = i + 1 {
    result.push(arr[i])
  }
  result.push(value)
  for i = index; i < arr.length(); i = i + 1 {
    result.push(arr[i])
  }
  result
}

///| 从数组移除指定位置的UInt16元素
fn array_remove_at_uint16(arr : Array[UInt16], index : Int) -> Array[UInt16] {
  let result = []
  for i = 0; i < arr.length(); i = i + 1 {
    if i != index {
      result.push(arr[i])
    }
  }
  result
}

///| 计算64位整数的人口计数（置位数）
fn popcount(value : UInt64) -> Int {
  let mut count = 0
  let mut v = value
  while v != 0UL {
    count = count + 1
    v = v & (v - 1UL) // 清除最低位的1
  }
  count
}

// 暂时用简单实现替代复杂的混合操作
///|
fn container_union_generic(
  container1 : Container,
  container2 : Container
) -> Container {
  let arr1 = container_to_array(container1)
  let arr2 = container_to_array(container2)
  let union_arr = array_container_union(arr1, arr2)
  if union_arr.length() >= ARRAY_CONTAINER_MAX_SIZE {
    // 需要实现数组转位图容器的逻辑
    array_to_bitmap_container(union_arr)
  } else {
    ArrayContainer(union_arr)
  }
}

///|
fn container_intersect_generic(
  container1 : Container,
  container2 : Container
) -> Container {
  let arr1 = container_to_array(container1)
  let arr2 = container_to_array(container2)
  ArrayContainer(array_container_intersect(arr1, arr2))
}

///|
fn container_difference_generic(
  container1 : Container,
  container2 : Container
) -> Container {
  let arr1 = container_to_array(container1)
  let arr2 = container_to_array(container2)
  ArrayContainer(array_container_difference(arr1, arr2))
}

// 简化的混合操作实现
///|
fn bitmap_container_union_with_array(
  bitmap : FixedArray[UInt64],
  arr : Array[UInt16]
) -> FixedArray[UInt64] {
  let result = FixedArray::make(1024, 0UL)
  for i = 0; i < 1024; i = i + 1 {
    result[i] = bitmap[i]
  }
  for i = 0; i < arr.length(); i = i + 1 {
    let value = arr[i]
    let word_index = value.to_int() / 64
    let bit_index = value.to_int() % 64
    result[word_index] = result[word_index] | (1UL << bit_index)
  }
  result
}

///|
fn array_container_intersect_with_bitmap(
  arr : Array[UInt16],
  bitmap : FixedArray[UInt64]
) -> Array[UInt16] {
  let result = []
  for i = 0; i < arr.length(); i = i + 1 {
    let value = arr[i]
    if bitmap_container_contains(bitmap, value) {
      result.push(value)
    }
  }
  result
}

///|
fn array_container_difference_with_bitmap(
  arr : Array[UInt16],
  bitmap : FixedArray[UInt64]
) -> Array[UInt16] {
  let result = []
  for i = 0; i < arr.length(); i = i + 1 {
    let value = arr[i]
    if not(bitmap_container_contains(bitmap, value)) {
      result.push(value)
    }
  }
  result
}

///|
fn bitmap_container_difference_with_array(
  bitmap : FixedArray[UInt64],
  arr : Array[UInt16]
) -> FixedArray[UInt64] {
  let result = FixedArray::make(1024, 0UL)
  for i = 0; i < 1024; i = i + 1 {
    result[i] = bitmap[i]
  }
  for i = 0; i < arr.length(); i = i + 1 {
    let value = arr[i]
    let word_index = value.to_int() / 64
    let bit_index = value.to_int() % 64
    // Replace ~(1UL << bit_index) with (0xFFFFFFFFFFFFFFFFUL ^ (1UL << bit_index))
    result[word_index] = result[word_index] &
      (0xFFFFFFFFFFFFFFFFUL ^ (1UL << bit_index))
  }
  result
}

// 运行容器的简化实现（占位符）
///|
fn run_container_contains(runs : Array[Run], value : UInt16) -> Bool {
  // 简化实现：遍历所有运行段
  for i = 0; i < runs.length(); i = i + 1 {
    let run = runs[i]
    if value >= run.start && value <= run.start + run.length {
      return true
    }
  }
  false
}

///|
fn run_container_cardinality(runs : Array[Run]) -> Int {
  let mut count = 0
  for i = 0; i < runs.length(); i = i + 1 {
    count = count + runs[i].length.to_int() + 1
  }
  count
}

///|
fn run_container_to_array(runs : Array[Run]) -> Array[UInt16] {
  let result = []
  for i = 0; i < runs.length(); i = i + 1 {
    let run = runs[i]
    for j = 0; j <= run.length.to_int(); j = j + 1 {
      result.push(run.start + j.to_uint16())
    }
  }
  result
}
// 添加到 RoaringBitmap.mbt 文件末尾

// =============== 容器转换函数 ===============

///| 数组容器转换为位图容器
fn array_to_bitmap_container(arr : Array[UInt16]) -> Container {
  let bitmap = FixedArray::make(1024, 0UL)
  for i = 0; i < arr.length(); i = i + 1 {
    let value = arr[i]
    let word_index = value.to_int() / 64
    let bit_index = value.to_int() % 64
    bitmap[word_index] = bitmap[word_index] | (1UL << bit_index)
  }
  BitmapContainer(bitmap)
}

///| 位图容器转换为数组容器
fn bitmap_to_array_container(bitmap : FixedArray[UInt64]) -> Container {
  ArrayContainer(bitmap_container_to_array(bitmap))
}

///| 数组容器转换为运行长度编码容器（简化实现）
fn array_to_run_container(arr : Array[UInt16]) -> Container {
  if arr.length() == 0 {
    return RunContainer([])
  }
  let runs = []
  let mut current_start = arr[0]
  let mut current_length = 0
  for i = 1; i < arr.length(); i = i + 1 {
    let current_val = arr[i]
    let prev_val = arr[i - 1]
    if current_val == prev_val + 1 {
      // 连续，增加当前运行长度
      current_length = current_length + 1
    } else {
      // 不连续，结束当前运行，开始新运行
      let run = Run::{
        start: current_start,
        length: current_length.to_uint16(),
      }
      runs.push(run)
      current_start = current_val
      current_length = 0
    }
  }

  // 添加最后一个运行
  let last_run = Run::{
    start: current_start,
    length: current_length.to_uint16(),
  }
  runs.push(last_run)
  RunContainer(runs)
}

///| 运行容器转换为数组容器
fn run_to_array_container(runs : Array[Run]) -> Container {
  ArrayContainer(run_container_to_array(runs))
}

///| 位图容器转换为运行长度编码容器（简化实现）
fn bitmap_to_run_container(bitmap : FixedArray[UInt64]) -> Container {
  let arr = bitmap_container_to_array(bitmap)
  array_to_run_container(arr)
}

///| 运行容器转换为位图容器
fn run_to_bitmap_container(runs : Array[Run]) -> Container {
  let arr = run_container_to_array(runs)
  array_to_bitmap_container(arr)
}

///| 自动优化容器类型
pub fn optimize_container(container : Container) -> Container {
  match container {
    ArrayContainer(arr) => {
      let size = arr.length()
      if size >= ARRAY_CONTAINER_MAX_SIZE {
        // 检查是否适合运行长度编码
        if should_use_run_container(arr) {
          array_to_run_container(arr)
        } else {
          array_to_bitmap_container(arr)
        }
      } else {
        container
      }
    }
    BitmapContainer(bitmap) => {
      let cardinality = bitmap_container_cardinality(bitmap)
      if cardinality < ARRAY_CONTAINER_MAX_SIZE {
        bitmap_to_array_container(bitmap)
      } else {
        // 检查是否适合运行长度编码
        let arr = bitmap_container_to_array(bitmap)
        if should_use_run_container(arr) {
          bitmap_to_run_container(bitmap)
        } else {
          container
        }
      }
    }
    RunContainer(runs) => {
      let cardinality = run_container_cardinality(runs)
      if cardinality < ARRAY_CONTAINER_MAX_SIZE {
        run_to_array_container(runs)
      } else if cardinality >= ARRAY_CONTAINER_MAX_SIZE &&
        is_efficient_run_container(runs) == false {
        run_to_bitmap_container(runs)
      } else {
        container
      }
    }
  }
}

///| 判断是否应该使用运行长度编码容器
fn should_use_run_container(arr : Array[UInt16]) -> Bool {
  if arr.length() < 2 {
    return false
  }
  let mut run_count = 1
  let mut consecutive_count = 0
  for i = 1; i < arr.length(); i = i + 1 {
    if arr[i] == arr[i - 1] + 1 {
      consecutive_count = consecutive_count + 1
    } else {
      if consecutive_count > 0 {
        run_count = run_count + 1
      }
      consecutive_count = 0
    }
  }

  // 如果运行数量少于数组长度的一半，说明有很多连续段，适合RLE
  run_count < arr.length() / 2
}

///| 判断运行长度编码容器是否高效
fn is_efficient_run_container(runs : Array[Run]) -> Bool {
  if runs.length() == 0 {
    return false
  }
  let total_elements = run_container_cardinality(runs)
  let storage_cost = runs.length() * 4 // 每个Run占4字节
  let array_cost = total_elements * 2 // 数组容器每个元素占2字节

  // 如果RLE存储成本低于数组存储成本，则认为高效
  storage_cost < array_cost
}

///| 运行容器交集操作
fn run_container_intersect(
  runs1 : Array[Run],
  runs2 : Array[Run]
) -> Array[Run] {
  if runs1.length() == 0 || runs2.length() == 0 {
    return []
  }
  let result = []
  let mut i = 0
  let mut j = 0
  while i < runs1.length() && j < runs2.length() {
    let run1 = runs1[i]
    let run2 = runs2[j]

    // 计算每个运行段的结束位置
    let end1 = run1.start + run1.length
    let end2 = run2.start + run2.length

    // 找到重叠区间
    let overlap_start = if run1.start > run2.start {
      run1.start
    } else {
      run2.start
    }
    let overlap_end = if end1 < end2 { end1 } else { end2 }
    if overlap_start <= overlap_end {
      // 有重叠，创建交集运行段
      let intersect_run = Run::{
        start: overlap_start,
        length: overlap_end - overlap_start,
      }
      result.push(intersect_run)
    }

    // 移动指针：结束位置较小的运行段先移动
    if end1 <= end2 {
      i = i + 1
    }
    if end2 <= end1 {
      j = j + 1
    }
  }
  result
}

///| 运行容器差集操作 (runs1 - runs2)
fn run_container_difference(
  runs1 : Array[Run],
  runs2 : Array[Run]
) -> Array[Run] {
  if runs1.length() == 0 {
    return []
  }
  if runs2.length() == 0 {
    return runs1
  }
  let result = []
  let mut i = 0
  let mut j = 0
  while i < runs1.length() {
    let mut current_run = runs1[i]
    let mut current_end = current_run.start + current_run.length
    let mut processed = false

    // 检查当前运行段与所有 runs2 中的运行段的关系
    while j < runs2.length() && not(processed) {
      let run2 = runs2[j]
      let end2 = run2.start + run2.length
      if run2.start > current_end {
        // run2 完全在当前运行段右边，当前运行段完全保留
        result.push(current_run)
        processed = true
      } else if end2 < current_run.start {
        // run2 完全在当前运行段左边，移动到下一个 run2
        j = j + 1
      } else {
        // 有重叠，需要分割当前运行段

        // 如果当前运行段的开始部分不重叠，保留这部分
        if current_run.start < run2.start {
          let left_part = Run::{
            start: current_run.start,
            length: run2.start - current_run.start - 1,
          }
          result.push(left_part)
        }

        // 如果当前运行段的结束部分不重叠，更新当前运行段为右边部分
        if current_end > end2 {
          current_run = Run::{ start: end2 + 1, length: current_end - end2 - 1 }
          current_end = current_run.start + current_run.length
          j = j + 1
        } else {
          // 当前运行段完全被覆盖或结束
          processed = true
          if end2 >= current_end {
            j = j + 1
          }
        }
      }
    }

    // 如果当前运行段还有剩余且没有被处理，添加到结果
    if not(processed) && j >= runs2.length() {
      result.push(current_run)
    }
    i = i + 1
    // 重置 j 为下一个可能相关的运行段
    j = find_next_relevant_run(runs2, current_run.start)
  }
  result
}

///| 找到下一个可能与给定位置相关的运行段索引
fn find_next_relevant_run(runs : Array[Run], position : UInt16) -> Int {
  let mut index = 0
  while index < runs.length() {
    let run = runs[index]
    let end = run.start + run.length
    if end >= position {
      return index
    }
    index = index + 1
  }
  runs.length()
}

///| 运行容器并集操作（完善实现）
fn run_container_union(runs1 : Array[Run], runs2 : Array[Run]) -> Array[Run] {
  if runs1.length() == 0 {
    return runs2
  }
  if runs2.length() == 0 {
    return runs1
  }

  // 合并两个运行段数组并排序
  let mut all_runs = []
  for i = 0; i < runs1.length(); i = i + 1 {
    all_runs.push(runs1[i])
  }
  for i = 0; i < runs2.length(); i = i + 1 {
    all_runs.push(runs2[i])
  }

  // 按开始位置排序
  all_runs = sort_runs(all_runs)

  // 合并重叠的运行段
  merge_overlapping_runs(all_runs)
}

///| 对运行段数组按开始位置排序
fn sort_runs(runs : Array[Run]) -> Array[Run] {
  if runs.length() <= 1 {
    return runs
  }

  // 简单的插入排序（对于小数组足够高效）
  let mut sorted = [runs[0]]
  for i = 1; i < runs.length(); i = i + 1 {
    let current = runs[i]
    let mut inserted = false
    for j = 0; j < sorted.length(); j = j + 1 {
      if current.start < sorted[j].start {
        sorted = array_insert_at_run(sorted, j, current)
        inserted = true
        break
      }
    }
    if not(inserted) {
      sorted.push(current)
    }
  }
  sorted
}

///| 在指定位置插入运行段
fn array_insert_at_run(arr : Array[Run], index : Int, run : Run) -> Array[Run] {
  let result = []
  for i = 0; i < index; i = i + 1 {
    result.push(arr[i])
  }
  result.push(run)
  for i = index; i < arr.length(); i = i + 1 {
    result.push(arr[i])
  }
  result
}

///| 合并重叠的运行段
fn merge_overlapping_runs(runs : Array[Run]) -> Array[Run] {
  if runs.length() <= 1 {
    return runs
  }
  let result = []
  let mut current = runs[0]
  for i = 1; i < runs.length(); i = i + 1 {
    let next = runs[i]
    let current_end = current.start + current.length
    let next_start = next.start
    if next_start <= current_end + 1 {
      // 运行段重叠或相邻，合并
      let next_end = next.start + next.length
      let merged_end = if current_end > next_end {
        current_end
      } else {
        next_end
      }
      current = Run::{
        start: current.start,
        length: merged_end - current.start,
      }
    } else {
      // 运行段不重叠，保存当前运行段，开始新的运行段
      result.push(current)
      current = next
    }
  }

  // 添加最后一个运行段
  result.push(current)
  result
}

///| 改进的运行容器添加元素操作
fn run_container_add(runs : Array[Run], value : UInt16) -> Array[Run] {
  if runs.length() == 0 {
    return [Run::{ start: value, length: 0 }]
  }
  let result = []
  let mut inserted = false
  for i = 0; i < runs.length(); i = i + 1 {
    let run = runs[i]
    let run_end = run.start + run.length
    if value < run.start {
      if value + 1 == run.start {
        // 扩展运行段的开始
        let extended_run = Run::{ start: value, length: run.length + 1 }
        result.push(extended_run)
      } else {
        // 插入新的运行段
        if not(inserted) {
          result.push(Run::{ start: value, length: 0 })
          inserted = true
        }
        result.push(run)
      }
    } else if value >= run.start && value <= run_end {
      // 值已在运行段中，直接添加运行段
      result.push(run)
      inserted = true
    } else if value == run_end + 1 {
      // 扩展运行段的结束
      let extended_run = Run::{ start: run.start, length: run.length + 1 }
      result.push(extended_run)
      inserted = true
    } else {
      result.push(run)
    }
  }

  // 如果还没插入，添加到末尾
  if not(inserted) {
    result.push(Run::{ start: value, length: 0 })
  }

  // 合并可能的重叠运行段
  merge_overlapping_runs(result)
}

///| 改进的运行容器移除元素操作
fn run_container_remove(runs : Array[Run], value : UInt16) -> Array[Run] {
  let result = []
  for i = 0; i < runs.length(); i = i + 1 {
    let run = runs[i]
    let run_end = run.start + run.length
    if value < run.start || value > run_end {
      // 值不在当前运行段中，保持运行段不变
      result.push(run)
    } else if run.start == run_end && run.start == value {
      // 运行段只有一个元素且就是要移除的值，跳过这个运行段
      continue
    } else if value == run.start {
      // 移除运行段的第一个元素
      if run.length > 0 {
        let new_run = Run::{ start: run.start + 1, length: run.length - 1 }
        result.push(new_run)
      }
    } else if value == run_end {
      // 移除运行段的最后一个元素
      let new_run = Run::{ start: run.start, length: run.length - 1 }
      result.push(new_run)
    } else {
      // 移除运行段中间的元素，需要分割运行段
      let left_run = Run::{ start: run.start, length: value - run.start - 1 }
      let right_run = Run::{ start: value + 1, length: run_end - value }
      result.push(left_run)
      result.push(right_run)
    }
  }
  result
}

///| 检查两个bitmap是否相等
pub fn equals(self : RoaringBitmap, other : RoaringBitmap) -> Bool {
  if self.size != other.size {
    return false
  }
  if self.containers.length() != other.containers.length() {
    return false
  }
  for i = 0; i < self.containers.length(); i = i + 1 {
    let c1 = self.containers[i]
    let c2 = other.containers[i]
    if c1.key != c2.key || c1.cardinality != c2.cardinality {
      return false
    }
    // 这里需要实现容器相等性检查
    if not(containers_equal(c1.container, c2.container)) {
      return false
    }
  }
  true
}

///| 获取最小值
pub fn min(self : RoaringBitmap) -> UInt? {
  if self.is_empty() {
    return None
  }
  let first_container = self.containers[0]
  let min_in_container = container_min(first_container.container)
  let high_bits = first_container.key.to_int().reinterpret_as_uint() << 16
  Some(high_bits | min_in_container.to_int().reinterpret_as_uint())
}

///| 获取最大值
pub fn max(self : RoaringBitmap) -> UInt? {
  if self.is_empty() {
    return None
  }
  let last_container = self.containers[self.containers.length() - 1]
  let max_in_container = container_max(last_container.container)
  let high_bits = last_container.key.to_int().reinterpret_as_uint() << 16
  Some(high_bits | max_in_container.to_int().reinterpret_as_uint())
}

///| 迭代器支持
pub fn iter(self : RoaringBitmap, f : (UInt) -> Unit) -> Unit {
  for i = 0; i < self.containers.length(); i = i + 1 {
    let container = self.containers[i]
    let high_bits = container.key.to_int().reinterpret_as_uint() << 16
    let values = container_to_array(container.container)
    for j = 0; j < values.length(); j = j + 1 {
      f(high_bits | values[j].to_int().reinterpret_as_uint())
    }
  }
}

///| 范围查询
pub fn range(self : RoaringBitmap, start : UInt, end : UInt) -> RoaringBitmap {
  let mut result = new()
  for i = 0; i < self.containers.length(); i = i + 1 {
    let container = self.containers[i]
    let high_bits = container.key.to_int().reinterpret_as_uint() << 16
    let values = container_to_array(container.container)
    for j = 0; j < values.length(); j = j + 1 {
      let value = high_bits | values[j].to_int().reinterpret_as_uint()
      if value >= start && value <= end {
        result = result.add(value)
      }
    }
  }
  result
}

///| 计算两个bitmap的Jaccard相似度
pub fn jaccard_similarity(
  self : RoaringBitmap,
  other : RoaringBitmap
) -> Double {
  let intersection_size = self.intersect(other).size()
  let union_size = self.union(other).size()
  if union_size == 0 {
    return 1.0
  }
  intersection_size.to_double() / union_size.to_double()
}

// =============== 容器最小值/最大值函数 ===============

///| 获取容器中的最小值
fn container_min(container : Container) -> UInt16 {
  match container {
    ArrayContainer(arr) => array_container_min(arr)
    BitmapContainer(bitmap) => bitmap_container_min(bitmap)
    RunContainer(runs) => run_container_min(runs)
  }
}

///| 获取容器中的最大值
fn container_max(container : Container) -> UInt16 {
  match container {
    ArrayContainer(arr) => array_container_max(arr)
    BitmapContainer(bitmap) => bitmap_container_max(bitmap)
    RunContainer(runs) => run_container_max(runs)
  }
}

///| 检查两个容器是否相等
fn containers_equal(container1 : Container, container2 : Container) -> Bool {
  match (container1, container2) {
    (ArrayContainer(arr1), ArrayContainer(arr2)) =>
      arrays_equal_uint16(arr1, arr2)
    (BitmapContainer(bitmap1), BitmapContainer(bitmap2)) =>
      bitmaps_equal(bitmap1, bitmap2)
    (RunContainer(runs1), RunContainer(runs2)) => runs_equal(runs1, runs2)
    _ => {
      // 不同类型的容器，转换为数组后比较
      let arr1 = container_to_array(container1)
      let arr2 = container_to_array(container2)
      arrays_equal_uint16(arr1, arr2)
    }
  }
}

// =============== 数组容器最小值/最大值 ===============

///| 数组容器最小值
fn array_container_min(arr : Array[UInt16]) -> UInt16 {
  if arr.length() == 0 {
    abort("Empty array container")
  }
  arr[0] // 数组已排序，第一个元素是最小值
}

///| 数组容器最大值
fn array_container_max(arr : Array[UInt16]) -> UInt16 {
  if arr.length() == 0 {
    abort("Empty array container")
  }
  arr[arr.length() - 1] // 数组已排序，最后一个元素是最大值
}

///| 检查两个UInt16数组是否相等
fn arrays_equal_uint16(arr1 : Array[UInt16], arr2 : Array[UInt16]) -> Bool {
  if arr1.length() != arr2.length() {
    return false
  }
  for i = 0; i < arr1.length(); i = i + 1 {
    if arr1[i] != arr2[i] {
      return false
    }
  }
  true
}

// =============== 位图容器最小值/最大值 ===============

///| 位图容器最小值
fn bitmap_container_min(bitmap : FixedArray[UInt64]) -> UInt16 {
  for word_index = 0; word_index < 1024; word_index = word_index + 1 {
    let word = bitmap[word_index]
    if word != 0UL {
      // 找到第一个非零的64位字
      for bit_index = 0; bit_index < 64; bit_index = bit_index + 1 {
        if (word & (1UL << bit_index)) != 0UL {
          let value = word_index * 64 + bit_index
          return value.to_uint16()
        }
      }
    }
  }
  abort("Empty bitmap container")
}

///| 位图容器最大值
fn bitmap_container_max(bitmap : FixedArray[UInt64]) -> UInt16 {
  // 从后往前搜索
  for word_index = 1023; word_index >= 0; word_index = word_index - 1 {
    let word = bitmap[word_index]
    if word != 0UL {
      // 找到最后一个非零的64位字
      for bit_index = 63; bit_index >= 0; bit_index = bit_index - 1 {
        if (word & (1UL << bit_index)) != 0UL {
          let value = word_index * 64 + bit_index
          return value.to_uint16()
        }
      }
    }
  }
  abort("Empty bitmap container")
}

///| 检查两个位图是否相等
fn bitmaps_equal(
  bitmap1 : FixedArray[UInt64],
  bitmap2 : FixedArray[UInt64]
) -> Bool {
  for i = 0; i < 1024; i = i + 1 {
    if bitmap1[i] != bitmap2[i] {
      return false
    }
  }
  true
}

// =============== 运行容器最小值/最大值 ===============

///| 运行容器最小值
fn run_container_min(runs : Array[Run]) -> UInt16 {
  if runs.length() == 0 {
    abort("Empty run container")
  }

  // 找到起始位置最小的运行段
  let mut min_start = runs[0].start
  for i = 1; i < runs.length(); i = i + 1 {
    if runs[i].start < min_start {
      min_start = runs[i].start
    }
  }
  min_start
}

///| 运行容器最大值
fn run_container_max(runs : Array[Run]) -> UInt16 {
  if runs.length() == 0 {
    abort("Empty run container")
  }

  // 找到结束位置最大的运行段
  let mut max_end = runs[0].start + runs[0].length
  for i = 1; i < runs.length(); i = i + 1 {
    let end = runs[i].start + runs[i].length
    if end > max_end {
      max_end = end
    }
  }
  max_end
}

///| 检查两个运行段数组是否相等
fn runs_equal(runs1 : Array[Run], runs2 : Array[Run]) -> Bool {
  if runs1.length() != runs2.length() {
    return false
  }
  for i = 0; i < runs1.length(); i = i + 1 {
    let run1 = runs1[i]
    let run2 = runs2[i]
    if run1.start != run2.start || run1.length != run2.length {
      return false
    }
  }
  true
}

// =============== 容器检查函数 ===============

///| 检查容器是否为空
fn container_is_empty(container : Container) -> Bool {
  match container {
    ArrayContainer(arr) => arr.length() == 0
    BitmapContainer(bitmap) => bitmap_container_cardinality(bitmap) == 0
    RunContainer(runs) => runs.length() == 0
  }
}

///| 获取容器中的第一个元素（最小值）
pub fn container_first(container : Container) -> UInt16? {
  if container_is_empty(container) {
    return None
  }
  Some(container_min(container))
}

///| 获取容器中的最后一个元素（最大值）
pub fn container_last(container : Container) -> UInt16? {
  if container_is_empty(container) {
    return None
  }
  Some(container_max(container))
}

///| 获取容器中指定索引的元素
pub fn container_get_at(container : Container, index : Int) -> UInt16? {
  if index < 0 || index >= container_cardinality(container) {
    return None
  }
  match container {
    ArrayContainer(arr) => Some(arr[index])
    BitmapContainer(bitmap) => {
      let arr = bitmap_container_to_array(bitmap)
      Some(arr[index])
    }
    RunContainer(runs) => {
      let arr = run_container_to_array(runs)
      Some(arr[index])
    }
  }
}

///| 查找容器中指定值的排名（从0开始）
pub fn container_rank(container : Container, value : UInt16) -> Int {
  match container {
    ArrayContainer(arr) => array_container_rank(arr, value)
    BitmapContainer(bitmap) => bitmap_container_rank(bitmap, value)
    RunContainer(runs) => run_container_rank(runs, value)
  }
}

///| 数组容器中查找值的排名
fn array_container_rank(arr : Array[UInt16], value : UInt16) -> Int {
  let mut rank = 0
  for i = 0; i < arr.length(); i = i + 1 {
    if arr[i] < value {
      rank = rank + 1
    } else {
      break
    }
  }
  rank
}

///| 位图容器中查找值的排名
fn bitmap_container_rank(bitmap : FixedArray[UInt64], value : UInt16) -> Int {
  let word_index = value.to_int() / 64
  let bit_index = value.to_int() % 64
  let mut rank = 0

  // 计算前面完整字的位数
  for i = 0; i < word_index; i = i + 1 {
    rank = rank + popcount(bitmap[i])
  }

  // 计算当前字中前面位的位数
  let current_word = bitmap[word_index]
  let mask = (1UL << bit_index) - 1UL
  rank = rank + popcount(current_word & mask)
  rank
}

///| 运行容器中查找值的排名
fn run_container_rank(runs : Array[Run], value : UInt16) -> Int {
  let mut rank = 0
  for i = 0; i < runs.length(); i = i + 1 {
    let run = runs[i]
    let run_end = run.start + run.length
    if value < run.start {
      // 值在当前运行段之前
      break
    } else if value > run_end {
      // 值在当前运行段之后，加上整个运行段的长度
      rank = rank + run.length.to_int() + 1
    } else {
      // 值在当前运行段内
      rank = rank + (value - run.start).to_int()
      break
    }
  }
  rank
}

///| 检查是否为子集
pub fn is_subset(self : RoaringBitmap, other : RoaringBitmap) -> Bool {
  if self.size > other.size {
    return false
  }

  // 逐容器检查
  let mut i = 0 // self的容器索引
  let mut j = 0 // other的容器索引
  while i < self.containers.length() && j < other.containers.length() {
    let self_container = self.containers[i]
    let other_container = other.containers[j]
    if self_container.key < other_container.key {
      // self有一个容器在other中不存在，不是子集
      return false
    } else if self_container.key > other_container.key {
      // other的这个容器不包含self的元素，继续
      j = j + 1
    } else {
      // 相同的高16位，检查容器是否为子集
      if not(
          container_is_subset(
            self_container.container,
            other_container.container,
          ),
        ) {
        return false
      }
      i = i + 1
      j = j + 1
    }
  }

  // 如果self还有剩余容器，说明不是子集
  i >= self.containers.length()
}

///| 检查容器是否为子集
fn container_is_subset(container1 : Container, container2 : Container) -> Bool {
  match (container1, container2) {
    (ArrayContainer(arr1), ArrayContainer(arr2)) =>
      array_container_is_subset(arr1, arr2)
    (ArrayContainer(arr), BitmapContainer(bitmap)) =>
      array_subset_of_bitmap(arr, bitmap)
    (BitmapContainer(bitmap1), BitmapContainer(bitmap2)) =>
      bitmap_container_is_subset(bitmap1, bitmap2)
    (BitmapContainer(bitmap), ArrayContainer(arr)) =>
      bitmap_subset_of_array(bitmap, arr)
    (RunContainer(runs1), RunContainer(runs2)) =>
      run_container_is_subset(runs1, runs2)
    _ => {
      // 混合类型，转换为数组后比较
      let arr1 = container_to_array(container1)
      let arr2 = container_to_array(container2)
      array_container_is_subset(arr1, arr2)
    }
  }
}

///| 数组容器子集检查
fn array_container_is_subset(
  arr1 : Array[UInt16],
  arr2 : Array[UInt16]
) -> Bool {
  if arr1.length() > arr2.length() {
    return false
  }
  let mut i = 0
  let mut j = 0
  while i < arr1.length() && j < arr2.length() {
    if arr1[i] < arr2[j] {
      // arr1中的元素在arr2中不存在
      return false
    } else if arr1[i] > arr2[j] {
      j = j + 1
    } else {
      // 相等，继续
      i = i + 1
      j = j + 1
    }
  }

  // 如果arr1还有剩余元素，说明不是子集
  i >= arr1.length()
}

///| 数组是否为位图的子集
fn array_subset_of_bitmap(
  arr : Array[UInt16],
  bitmap : FixedArray[UInt64]
) -> Bool {
  for i = 0; i < arr.length(); i = i + 1 {
    if not(bitmap_container_contains(bitmap, arr[i])) {
      return false
    }
  }
  true
}

///| 位图容器子集检查
fn bitmap_container_is_subset(
  bitmap1 : FixedArray[UInt64],
  bitmap2 : FixedArray[UInt64]
) -> Bool {
  for i = 0; i < 1024; i = i + 1 {
    // bitmap1的每一位都必须在bitmap2中存在
    if (bitmap1[i] & bitmap2[i]) != bitmap1[i] {
      return false
    }
  }
  true
}

///| 位图是否为数组的子集
fn bitmap_subset_of_array(
  bitmap : FixedArray[UInt64],
  arr : Array[UInt16]
) -> Bool {
  // 将位图转换为数组，然后检查
  let bitmap_arr = bitmap_container_to_array(bitmap)
  array_container_is_subset(bitmap_arr, arr)
}

///| 运行容器子集检查
fn run_container_is_subset(runs1 : Array[Run], runs2 : Array[Run]) -> Bool {
  // 简化实现：转换为数组后比较
  let arr1 = run_container_to_array(runs1)
  let arr2 = run_container_to_array(runs2)
  array_container_is_subset(arr1, arr2)
}

///| 对称差集 (XOR) - 在两个集合中但不在交集中的元素
pub fn xor(self : RoaringBitmap, other : RoaringBitmap) -> RoaringBitmap {
  if self.is_empty() {
    return other
  }
  if other.is_empty() {
    return self
  }
  let result_containers = []
  let mut i = 0
  let mut j = 0
  let mut total_size = 0
  while i < self.containers.length() && j < other.containers.length() {
    let container1 = self.containers[i]
    let container2 = other.containers[j]
    if container1.key < container2.key {
      // 只在self中存在
      result_containers.push(container1)
      total_size = total_size + container1.cardinality
      i = i + 1
    } else if container1.key > container2.key {
      // 只在other中存在
      result_containers.push(container2)
      total_size = total_size + container2.cardinality
      j = j + 1
    } else {
      // 相同key，计算XOR
      let xor_container = container_xor(
        container1.container,
        container2.container,
      )
      let xor_cardinality = container_cardinality(xor_container)
      if xor_cardinality > 0 {
        let xor_high_container = HighContainer::{
          key: container1.key,
          container: xor_container,
          cardinality: xor_cardinality,
        }
        result_containers.push(xor_high_container)
        total_size = total_size + xor_cardinality
      }
      i = i + 1
      j = j + 1
    }
  }

  // 添加剩余的容器
  while i < self.containers.length() {
    let container = self.containers[i]
    result_containers.push(container)
    total_size = total_size + container.cardinality
    i = i + 1
  }
  while j < other.containers.length() {
    let container = other.containers[j]
    result_containers.push(container)
    total_size = total_size + container.cardinality
    j = j + 1
  }
  RoaringBitmap::{ containers: result_containers, size: total_size }
}

///| 容器XOR操作
fn container_xor(container1 : Container, container2 : Container) -> Container {
  match (container1, container2) {
    (ArrayContainer(arr1), ArrayContainer(arr2)) =>
      ArrayContainer(array_container_xor(arr1, arr2))
    (ArrayContainer(arr), BitmapContainer(bitmap)) =>
      array_xor_bitmap_container(arr, bitmap)
    (BitmapContainer(bitmap), ArrayContainer(arr)) =>
      array_xor_bitmap_container(arr, bitmap)
    (BitmapContainer(bitmap1), BitmapContainer(bitmap2)) => {
      let xor_bitmap = bitmap_container_xor(bitmap1, bitmap2)
      let cardinality = bitmap_container_cardinality(xor_bitmap)
      if cardinality < ARRAY_CONTAINER_MAX_SIZE {
        bitmap_to_array_container(xor_bitmap)
      } else {
        BitmapContainer(xor_bitmap)
      }
    }
    (RunContainer(runs1), RunContainer(runs2)) =>
      RunContainer(run_container_xor(runs1, runs2))
    _ => container_xor_generic(container1, container2)
  }
}

///| 数组容器XOR
fn array_container_xor(
  arr1 : Array[UInt16],
  arr2 : Array[UInt16]
) -> Array[UInt16] {
  let result = []
  let mut i = 0
  let mut j = 0
  while i < arr1.length() && j < arr2.length() {
    let val1 = arr1[i]
    let val2 = arr2[j]
    if val1 < val2 {
      result.push(val1) // 只在arr1中
      i = i + 1
    } else if val1 > val2 {
      result.push(val2) // 只在arr2中
      j = j + 1
    } else {
      // 相等，跳过（XOR中相同元素抵消）
      i = i + 1
      j = j + 1
    }
  }

  // 添加剩余元素
  while i < arr1.length() {
    result.push(arr1[i])
    i = i + 1
  }
  while j < arr2.length() {
    result.push(arr2[j])
    j = j + 1
  }
  result
}

///| 数组与位图容器XOR
fn array_xor_bitmap_container(
  arr : Array[UInt16],
  bitmap : FixedArray[UInt64]
) -> Container {
  let result_bitmap = FixedArray::make(1024, 0UL)

  // 复制原位图
  for i = 0; i < 1024; i = i + 1 {
    result_bitmap[i] = bitmap[i]
  }

  // 对数组中的每个元素执行XOR
  for i = 0; i < arr.length(); i = i + 1 {
    let value = arr[i]
    let word_index = value.to_int() / 64
    let bit_index = value.to_int() % 64
    let bit_mask = 1UL << bit_index
    result_bitmap[word_index] = result_bitmap[word_index] ^ bit_mask
  }
  let cardinality = bitmap_container_cardinality(result_bitmap)
  if cardinality < ARRAY_CONTAINER_MAX_SIZE {
    bitmap_to_array_container(result_bitmap)
  } else {
    BitmapContainer(result_bitmap)
  }
}

///| 位图容器XOR
fn bitmap_container_xor(
  bitmap1 : FixedArray[UInt64],
  bitmap2 : FixedArray[UInt64]
) -> FixedArray[UInt64] {
  let result = FixedArray::make(1024, 0UL)
  for i = 0; i < 1024; i = i + 1 {
    result[i] = bitmap1[i] ^ bitmap2[i]
  }
  result
}

///| 运行容器XOR（简化实现）
fn run_container_xor(runs1 : Array[Run], runs2 : Array[Run]) -> Array[Run] {
  // 简化实现：转换为数组后计算XOR
  let arr1 = run_container_to_array(runs1)
  let arr2 = run_container_to_array(runs2)
  let xor_arr = array_container_xor(arr1, arr2)

  // 转换回运行段格式
  if should_use_run_container(xor_arr) {
    match array_to_run_container(xor_arr) {
      RunContainer(runs) => runs
      _ => [] // 不应该发生
    }
  } else {
    // 如果不适合运行长度编码，返回空运行段
    []
  }
}

///| 容器XOR通用实现
fn container_xor_generic(
  container1 : Container,
  container2 : Container
) -> Container {
  let arr1 = container_to_array(container1)
  let arr2 = container_to_array(container2)
  let xor_arr = array_container_xor(arr1, arr2)
  if xor_arr.length() >= ARRAY_CONTAINER_MAX_SIZE {
    array_to_bitmap_container(xor_arr)
  } else {
    ArrayContainer(xor_arr)
  }
}

///| 批量添加元素（高性能版本）
pub fn add_many(self : RoaringBitmap, values : Array[UInt]) -> RoaringBitmap {
  if values.length() == 0 {
    return self
  }

  // 按高16位分组
  let groups = []
  let mut current_high = None
  let mut current_lows = []

  // 先对values按值排序（简化分组逻辑）
  let sorted_values = sort_uint_array(values)
  for i = 0; i < sorted_values.length(); i = i + 1 {
    let value = sorted_values[i]
    let high = extract_high_16(value)
    let low = extract_low_16(value)
    match current_high {
      None => {
        current_high = Some(high)
        current_lows = [low]
      }
      Some(prev_high) =>
        if high == prev_high {
          // 同一组，避免重复
          if current_lows.length() == 0 ||
            current_lows[current_lows.length() - 1] != low {
            current_lows.push(low)
          }
        } else {
          // 新组，保存当前组
          groups.push((prev_high, current_lows))
          current_high = Some(high)
          current_lows = [low]
        }
    }
  }

  // 保存最后一组
  match current_high {
    Some(high) => groups.push((high, current_lows))
    None => ()
  }

  // 批量处理每个组
  let mut result = self
  for i = 0; i < groups.length(); i = i + 1 {
    let (high, lows) = groups[i]
    result = add_sorted_lows_to_bitmap(result, high, lows)
  }
  result
}

///| 批量添加排序的低16位值到指定高16位
fn add_sorted_lows_to_bitmap(
  bitmap : RoaringBitmap,
  high : UInt16,
  lows : Array[UInt16]
) -> RoaringBitmap {
  match find_container_index(bitmap.containers, high) {
    Found(index) => {
      // 容器存在，批量添加
      let container = bitmap.containers[index]
      let (new_container, added_count) = batch_add_to_existing_container(
        container.container,
        lows,
      )
      let new_cardinality = container.cardinality + added_count
      let new_high_container = HighContainer::{
        key: high,
        container: new_container,
        cardinality: new_cardinality,
      }
      let new_containers = array_replace_at(
        bitmap.containers,
        index,
        new_high_container,
      )
      RoaringBitmap::{
        containers: new_containers,
        size: bitmap.size + added_count,
      }
    }
    NotFound(insert_pos) => {
      // 容器不存在，创建新容器
      let new_container = if lows.length() >= ARRAY_CONTAINER_MAX_SIZE {
        array_to_bitmap_container(lows)
      } else {
        ArrayContainer(lows)
      }
      let new_high_container = HighContainer::{
        key: high,
        container: new_container,
        cardinality: lows.length(),
      }
      let new_containers = array_insert_at(
        bitmap.containers,
        insert_pos,
        new_high_container,
      )
      RoaringBitmap::{
        containers: new_containers,
        size: bitmap.size + lows.length(),
      }
    }
  }
}

///| 批量添加到现有容器
fn batch_add_to_existing_container(
  container : Container,
  lows : Array[UInt16]
) -> (Container, Int) {
  match container {
    ArrayContainer(arr) => {
      let (merged_arr, added_count) = merge_sorted_arrays_count_new(arr, lows)
      let new_container = if merged_arr.length() >= ARRAY_CONTAINER_MAX_SIZE {
        array_to_bitmap_container(merged_arr)
      } else {
        ArrayContainer(merged_arr)
      }
      (new_container, added_count)
    }
    BitmapContainer(bitmap) => {
      let (new_bitmap, added_count) = batch_add_to_bitmap(bitmap, lows)
      (BitmapContainer(new_bitmap), added_count)
    }
    RunContainer(runs) => {
      let (new_runs, added_count) = batch_add_to_runs(runs, lows)
      (RunContainer(new_runs), added_count)
    }
  }
}

///| 合并两个排序数组，返回合并结果和新增元素数量
fn merge_sorted_arrays_count_new(
  arr1 : Array[UInt16],
  arr2 : Array[UInt16]
) -> (Array[UInt16], Int) {
  let result = []
  let mut i = 0
  let mut j = 0
  let mut added_count = 0
  while i < arr1.length() && j < arr2.length() {
    if arr1[i] < arr2[j] {
      result.push(arr1[i])
      i = i + 1
    } else if arr1[i] > arr2[j] {
      result.push(arr2[j])
      added_count = added_count + 1
      j = j + 1
    } else {
      result.push(arr1[i]) // 相等，只添加一次
      i = i + 1
      j = j + 1
    }
  }

  // 添加剩余元素
  while i < arr1.length() {
    result.push(arr1[i])
    i = i + 1
  }
  while j < arr2.length() {
    result.push(arr2[j])
    added_count = added_count + 1
    j = j + 1
  }
  (result, added_count)
}

///| 批量添加到位图容器
fn batch_add_to_bitmap(
  bitmap : FixedArray[UInt64],
  lows : Array[UInt16]
) -> (FixedArray[UInt64], Int) {
  let new_bitmap = FixedArray::make(1024, 0UL)
  let mut added_count = 0

  // 复制原位图
  for i = 0; i < 1024; i = i + 1 {
    new_bitmap[i] = bitmap[i]
  }

  // 批量添加元素
  for i = 0; i < lows.length(); i = i + 1 {
    let value = lows[i]
    let word_index = value.to_int() / 64
    let bit_index = value.to_int() % 64
    let bit_mask = 1UL << bit_index
    if (new_bitmap[word_index] & bit_mask) == 0UL {
      // 元素不存在，添加它
      new_bitmap[word_index] = new_bitmap[word_index] | bit_mask
      added_count = added_count + 1
    }
  }
  (new_bitmap, added_count)
}

///| 批量添加到运行容器
fn batch_add_to_runs(
  runs : Array[Run],
  lows : Array[UInt16]
) -> (Array[Run], Int) {
  let mut new_runs = runs
  let mut added_count = 0
  for i = 0; i < lows.length(); i = i + 1 {
    let value = lows[i]
    if not(run_container_contains(new_runs, value)) {
      new_runs = run_container_add(new_runs, value)
      added_count = added_count + 1
    }
  }
  (new_runs, added_count)
}

///| UInt数组排序
fn sort_uint_array(arr : Array[UInt]) -> Array[UInt] {
  if arr.length() <= 1 {
    return arr
  }
  let sorted = []
  for i = 0; i < arr.length(); i = i + 1 {
    sorted.push(arr[i])
  }
  for i = 0; i < sorted.length() - 1; i = i + 1 {
    for j = 0; j < sorted.length() - 1 - i; j = j + 1 {
      if sorted[j] > sorted[j + 1] {
        let temp = sorted[j]
        sorted[j] = sorted[j + 1]
        sorted[j + 1] = temp
      }
    }
  }
  sorted
}
