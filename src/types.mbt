///| 容器配置常量
pub const ARRAY_CONTAINER_MAX_SIZE : Int = 4096

///|
pub const BITMAP_CONTAINER_SIZE : Int = 8192 // 2^16 / 8 = 8192 bytes = 1024 UInt64

///|
pub const RUN_CONTAINER_MAX_SIZE : Int = 2048

///| RoaringBitmap 错误类型
pub(all) enum RoaringError {
  InvalidInput(String)
  OutOfRange(String)
  SerializationError(String)
}

///| 容器类型枚举 - Roaring Bitmap 的核心优化策略
enum Container {
  // 数组容器：适用于稀疏数据（< 4096 个元素）
  ArrayContainer(Array[UInt16])

  // 位图容器：适用于密集数据（>= 4096 个元素）
  BitmapContainer(FixedArray[UInt64]) // 1024 个 UInt64，每个64位

  // 运行长度编码容器：适用于连续数据
  RunContainer(Array[Run])
}

///| 运行长度编码的运行段
pub(all) struct Run {
  start : UInt16 // 运行段的起始值
  length : UInt16 // 运行长度（实际元素个数 - 1）
}

///| 高级容器 - 处理 32 位整数的高 16 位
struct HighContainer {
  key : UInt16 // 高 16 位作为键
  container : Container // 对应的容器（存储低 16 位）
  cardinality : Int // 该容器中的元素个数
}

///| RoaringBitmap 主结构
pub struct RoaringBitmap {
  containers : Array[HighContainer] // 按 key 排序的容器数组
  mut size : Int // 总元素个数
}

///| 容器操作接口
pub trait ContainerOps {
  // 基本操作
  add(Self, UInt16) -> Self
  remove(Self, UInt16) -> Self
  contains(Self, UInt16) -> Bool

  // 集合操作
  union(Self, Self) -> Self
  intersect(Self, Self) -> Self
  difference(Self, Self) -> Self

  // 属性查询
  cardinality(Self) -> Int
  is_empty(Self) -> Bool

  // 转换操作
  to_array(Self) -> Array[UInt16]
  optimize(Self) -> Container // 自动选择最优容器类型
}

///| 迭代器类型
pub(all) enum RoaringIterator {
  ArrayIterator(ArrayIteratorState)
  BitmapIterator(BitmapIteratorState)
  RunIterator(RunIteratorState)
}

///| 数组迭代器状态
pub(all) struct ArrayIteratorState {
  values : Array[UInt16]
  index : Int
  high_bits : UInt // 修正：使用 UInt 而不是 UInt32
}

///| 位图迭代器状态
pub(all) struct BitmapIteratorState {
  bitmap : FixedArray[UInt64]
  word_index : Int
  bit_index : Int
  high_bits : UInt // 修正：使用 UInt 而不是 UInt32
}

///| 运行迭代器状态
pub(all) struct RunIteratorState {
  runs : Array[Run]
  run_index : Int
  position_in_run : Int
  high_bits : UInt // 修正：使用 UInt 而不是 UInt32
}

///| 统计信息结构
pub struct RoaringStats {
  total_containers : Int
  array_containers : Int
  bitmap_containers : Int
  run_containers : Int
  total_bytes : Int
  compression_ratio : Double
}

///| 二进制搜索结果
pub enum SearchResult {
  Found(Int) // 找到，返回索引
  NotFound(Int) // 未找到，返回应该插入的位置
}
