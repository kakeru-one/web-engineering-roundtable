require 'fileutils'

PAGE_SIZE = 4096

class PageId
  INVALID_PAGE_ID = 2**64 - 1

  attr_reader :id

  def initialize(id)
    @id = id
  end

  def valid?
    @id != INVALID_PAGE_ID
  end

  def to_u64
    @id
  end

  def self.from_bytes(bytes)
    id = bytes.unpack1('Q<') # Little-endian u64
    new(id)
  end
end

class DiskManager
  attr_reader :next_page_id, :heap_file

  def initialize(heap_file)
    @heap_file = heap_file
    @next_page_id = (File.size(heap_file) / PAGE_SIZE).to_i
  end

  def self.open(heap_file_path)
    unless File.exist?(heap_file_path)
      FileUtils.touch(heap_file_path) # ファイルが存在しない場合、空ファイルを作成
    end
    new(heap_file_path)
  end

  def read_page_data(page_id, data)
    offset = PAGE_SIZE * page_id.to_u64
    File.open(@heap_file, 'rb') do |file|
      file.seek(offset)
      file.read(PAGE_SIZE, data)
    end
  end

  def write_page_data(page_id, data)
    offset = PAGE_SIZE * page_id.to_u64
    File.open(@heap_file, 'r+b') do |file|
      file.seek(offset)
      file.write(data)
    end
  end

  def allocate_page
    page_id = @next_page_id
    @next_page_id += 1
    PageId.new(page_id)
  end

  def sync
    # Rubyでは明示的なファイルフラッシュは必要ないが、ここでは空のメソッドとして残す
  end
end

# 実行例
disk_manager = DiskManager.open('heap_file.txt')

# 新しいページを割り当てる
page_id = disk_manager.allocate_page

# ページにデータを書き込む
data_to_write = "\x00" * PAGE_SIZE
disk_manager.write_page_data(page_id, data_to_write)

# ページからデータを読み込む
data_to_read = "\x00" * PAGE_SIZE
disk_manager.read_page_data(page_id, data_to_read)

# データを同期
disk_manager.sync
