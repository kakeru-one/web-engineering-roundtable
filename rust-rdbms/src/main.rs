use std::convert::TryInto;
use std::fs::{File, OpenOptions};
use std::io::{self, prelude::*, SeekFrom};
use std::path::Path;

fn main() -> io::Result<()> {
    // DiskManagerを初期化
    let mut disk_manager = DiskManager::open("heap_file.txt")?;

    // 新しいページを割り当てる
    let page_id = disk_manager.allocate_page();

    // ページにデータを書き込む
    let data_to_write = [0u8; PAGE_SIZE]; // 4096バイトのデータ
    disk_manager.write_page_data(page_id, &data_to_write)?;

    // ページからデータを読み込む
    let mut data_to_read = [0u8; PAGE_SIZE];
    disk_manager.read_page_data(page_id, &mut data_to_read)?;

    // データを同期
    disk_manager.sync()?;

    Ok(())
}

// NOTE: デバッグ用のコード
// fn main() {
//     println!("{}", u64::MAX)
// }

#[derive(PartialEq, Copy, Clone)]
pub struct PageId(pub u64);
impl PageId {
    pub const INVALID_PAGE_ID: PageId = PageId(u64::MAX);

    pub fn valid(self) -> Option<PageId> {
        if self == Self::INVALID_PAGE_ID {
            None
        } else {
            Some(self)
        }
    }

    pub fn to_u64(self) -> u64 {
        self.0
    }
}

impl Default for PageId {
    fn default() -> Self {
        Self::INVALID_PAGE_ID
    }
}

impl From<Option<PageId>> for PageId {
    fn from(page_id: Option<PageId>) -> Self {
        page_id.unwrap_or_default()
    }
}

impl From<&[u8]> for PageId {
    fn from(bytes: &[u8]) -> Self {
        let arr = bytes.try_into().unwrap();
        PageId(u64::from_ne_bytes(arr))
    }
}

pub const PAGE_SIZE: usize = 4096;

pub struct DiskManager {
    heap_file: File,
    next_page_id: u64,
}

impl DiskManager {
    // コンストラクタ
    pub fn new(heap_file: File) -> io::Result<Self> {
        let heap_file_size = heap_file.metadata()?.len();
        // 一番下のページ番号を取得する
        let next_page_id = heap_file_size / PAGE_SIZE as u64;
        Ok(Self {
            heap_file,
            next_page_id,
        })
    }
    // ヒープファイルを開く
    pub fn open(heap_file_path: impl AsRef<Path>) -> io::Result<Self> {
        // io::Result<File> ディスクプリタ
        let heap_file = OpenOptions::new()
            .read(true)
            .write(true)
            .create(true)
            .open(heap_file_path)?; // エラーが返ってきたら早期return
        Self::new(heap_file)
    }

    // ヒープファイルの最後尾のデータを取得する
        // ヒープファイルとは1つのファイルで、pageとはヒープファイル内にあるデータを4096byteで区切ったもの
    pub fn read_page_data(&mut self, page_id: PageId, data: &mut [u8]) -> io::Result<()> {
        let offset = PAGE_SIZE as u64 * page_id.to_u64();
        self.heap_file.seek(SeekFrom::Start(offset))?;
        self.heap_file.read_exact(data)
    }

    // ヒープファイルの最後尾にdataを挿入する
        // ヒープファイルとは1つのファイルで、pageとはヒープファイル内にあるデータを4096byteで区切ったもの
    pub fn write_page_data(&mut self, page_id: PageId, data: &[u8]) -> io::Result<()> {
        // dataは4096byteの単位で渡ってくる
        // オフセットを計算
        // page_id = 2, last_page_byte=4096*2 = offset
        let offset = PAGE_SIZE as u64 * page_id.to_u64(); // u64とは符号なしの整数型
        // ページ先頭へシーク
        self.heap_file.seek(SeekFrom::Start(offset))?; // 先頭から4096*2byte進んだ位置にカーソルを合わせる
        // データを読み出す
        self.heap_file.write_all(data) // データを書き込む
    }

    pub fn allocate_page(&mut self) -> PageId {
        let page_id = self.next_page_id;
        self.next_page_id += 1;
        PageId(page_id)
    }

    // pub fn sync(&mut self) -> io::Result<()> {
    //     self.heap_file.flush()?;
    //     self.heap_file.sync_all()
    // }
}
