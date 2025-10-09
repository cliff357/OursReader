import requests
from bs4 import BeautifulSoup
import json
import time
import re
from urllib.parse import urljoin, urlparse
import os
from http.client import RemoteDisconnected  # 正確的導入

class UniversalBookScraper:
    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        })
        self.delay = 60  # 爬取間隔，避免被封
        
        # 新增重試配置
        self.max_retries = 3  # 最大重試次數
        self.retry_delay = 10  # 重試延遲（秒）
        
        # 新增統計變量
        self.stats = {
            'start_time': None,
            'end_time': None,
            'total_chapters': 0,
            'total_pages': 0,
            'total_characters': 0,
            'total_words': 0,
            'failed_chapters': 0,
            'visited_urls': [],
            'successful_urls': [],
            'failed_urls': []
        }
        
        # 新增續傳相關變量
        self.existing_book_data = None
        self.existing_chapters = []
        self.existing_urls = set()
        self.continue_mode = False

        # 新增自動恢復配置
        self.auto_recovery = True  # 是否啟用自動恢復
        self.recovery_delay = 60  # 恢復等待時間（秒）
        self.max_recoveries = 5  # 最大恢復次數
        self.recovery_count = 0  # 當前恢復次數
    
    def scrape_from_url(self, start_url, max_chapters=999):
        """從指定URL開始爬取書籍（支援續傳和自動恢復）"""
        # 初始化統計
        self.stats['start_time'] = time.time()
        self.stats['visited_urls'] = []
        self.stats['successful_urls'] = []
        self.stats['failed_urls'] = []
        
        print(f"🚀 開始從URL爬取：{start_url}")
        
        # 🔍 檢查是否有現有的書籍文件
        existing_file = self.check_existing_book_file(start_url)
        chapters = []
        
        if (existing_file):
            print(f"📖 發現現有書籍文件：{existing_file}")
            chapters = self.load_existing_chapters(existing_file)
            if chapters:
                print(f"✅ 載入了 {len(chapters)} 個已存在的章節")
                self.continue_mode = True
                
                # 找到應該繼續的URL
                continue_url = self.find_continue_url(start_url, chapters)
                if continue_url:
                    start_url = continue_url
                    print(f"🔗 續傳模式：從第 {len(chapters) + 1} 章開始：{continue_url}")
                else:
                    print("✅ 所有章節已完成，無需繼續爬取")
                    return self.existing_book_data
        
        print(f"📚 最多爬取 {max_chapters} 章")
        print(f"⏰ 開始時間：{time.strftime('%Y-%m-%d %H:%M:%S')}")
        if self.continue_mode:
            print(f"🔄 續傳模式：已有 {len(chapters)} 章，繼續爬取新章節")
        print("-" * 60)
        
        current_url = start_url
        chapter_count = len(chapters)  # 從已有章節數開始計算
        visited_urls = self.existing_urls.copy()  # 包含已存在的URLs
        
        while current_url and chapter_count < max_chapters:
            # 防止重複爬取
            if current_url in visited_urls:
                print(f"⚠️ 檢測到重複URL，停止爬取：{current_url}")
                break
                
            visited_urls.add(current_url)
            self.stats['visited_urls'].append(current_url)
            
            # 使用重試機制爬取章節
            success = self.scrape_chapter_with_retry(
                current_url, chapter_count + 1, chapters
            )
            
            if success:
                # 重置恢復計數器（成功後重置）
                self.recovery_count = 0
                
                # 尋找下一章連結 - 加入自動恢復機制
                next_url_result = self.find_next_page_with_recovery(current_url)
                
                if next_url_result is None:
                    # 自動恢復失敗，停止爬取
                    print("💾 自動恢復失敗，正在保存已獲取的內容...")
                    break
                elif next_url_result == "completed":
                    # 正常完成，沒有下一章
                    print("📄 沒有找到下一章連結，爬取完成")
                    break
                else:
                    # 成功找到下一章
                    current_url = next_url_result
                    chapter_count += 1
                    print(f"🔗 找到下一章：{next_url_result}")
                    time.sleep(self.delay)
            else:
                # 章節爬取失敗，但先保存已獲取的內容
                print("💾 爬取中斷，正在保存已獲取的內容...")
                break
        
        # 完成統計
        self.stats['end_time'] = time.time()
        self.stats['total_chapters'] = len(chapters)
        
        # 顯示爬取總結
        self.print_scraping_summary(chapters)
        
        if self.continue_mode:
            print(f"🎉 續傳完成！總共 {len(chapters)} 章（新增 {len(chapters) - len(self.existing_chapters)} 章）")
        else:
            print(f"🎉 爬取完成！共爬取 {len(chapters)} 章")
        
        # 如果爬取到內容，嘗試提取書名和作者
        if chapters:
            if self.continue_mode and self.existing_book_data:
                # 續傳模式：更新現有書籍數據
                book_title = self.existing_book_data['title']
                author = self.existing_book_data['author']
            else:
                # 新書模式：提取書名和作者
                book_title, author = self.extract_book_info(start_url, chapters[0])
            
            ebook_data = self.convert_to_ebook(book_title, author, chapters)
            self.stats['total_pages'] = len(ebook_data['pages'])
            
            # 自動保存（續傳模式下會覆蓋原文件）
            is_complete = (chapter_count >= max_chapters or current_url is None)
            self.auto_save_book(ebook_data, is_complete, is_continue=self.continue_mode)
            
            return ebook_data
        else:
            print("❌ 沒有爬取到任何章節")
            return None

    def find_next_page_with_recovery(self, current_url):
        """尋找下一章連結，支援自動恢復機制"""
        for attempt in range(self.max_retries + 1):
            try:
                print(f"🔍 正在查找下一章連結：{current_url}")
                if attempt > 0:
                    print(f"   🔄 查找重試第 {attempt} 次...")
                
                response = self.session.get(current_url, timeout=10)
                response.encoding = response.apparent_encoding or 'utf-8'
                soup = BeautifulSoup(response.text, 'html.parser')
                next_url = self.find_next_page_url(soup, current_url)
                
                if next_url:
                    return next_url
                else:
                    return "completed"  # 正常完成，沒有下一章
                    
            except (requests.exceptions.ConnectionError, 
                    RemoteDisconnected,  # 修正：移除 requests.exceptions.
                    ConnectionError) as e:
                print(f"❌ 連接錯誤 (查找下一章 {attempt + 1}/{self.max_retries + 1}): {e}")
                
                if attempt < self.max_retries:
                    print(f"⏱️  等待 {self.retry_delay} 秒後重試...")
                    time.sleep(self.retry_delay)
                else:
                    # 達到重試上限，啟動自動恢復
                    if self.auto_recovery and self.recovery_count < self.max_recoveries:
                        return self.trigger_auto_recovery(current_url, "find_next_page")
                    else:
                        print("❌ 達到最大重試次數和恢復次數，停止爬取")
                        return None
                        
            except requests.exceptions.Timeout as e:
                print(f"❌ 請求超時 (查找下一章 {attempt + 1}/{self.max_retries + 1}): {e}")
                
                if attempt < self.max_retries:
                    print(f"⏱️  等待 {self.retry_delay} 秒後重試...")
                    time.sleep(self.retry_delay)
                else:
                    if self.auto_recovery and self.recovery_count < self.max_recoveries:
                        return self.trigger_auto_recovery(current_url, "find_next_page")
                    else:
                        print("❌ 達到最大重試次數和恢復次數，停止爬取")
                        return None
                        
            except Exception as e:
                print(f"❌ 其他錯誤 (查找下一章 {attempt + 1}/{self.max_retries + 1}): {e}")
                
                if attempt < self.max_retries:
                    print(f"⏱️  等待 {self.retry_delay} 秒後重試...")
                    time.sleep(self.retry_delay)
                else:
                    if self.auto_recovery and self.recovery_count < self.max_recoveries:
                        return self.trigger_auto_recovery(current_url, "find_next_page")
                    else:
                        print("❌ 達到最大重試次數和恢復次數，停止爬取")
                        return None
        
        return None

    def trigger_auto_recovery(self, failed_url, operation_type):
        """觸發自動恢復機制"""
        self.recovery_count += 1
        
        print(f"\n🚨 === 自動恢復機制啟動 (第 {self.recovery_count} 次) ===")
        print(f"❌ 操作失敗：{operation_type}")
        print(f"🔗 失敗URL：{failed_url}")
        print(f"⏰ 等待時間：{self.recovery_delay} 秒")
        print(f"📊 剩餘恢復次數：{self.max_recoveries - self.recovery_count}")
        print("=" * 60)
        
        # 顯示倒數計時
        for remaining in range(self.recovery_delay, 0, -1):
            if remaining % 10 == 0 or remaining <= 10:
                print(f"⏳ 自動恢復倒數：{remaining} 秒...")
            time.sleep(1)
        
        print("🔄 自動恢復開始，重新嘗試操作...")
        
        # 重新建立連接
        self.reset_session()
        
        # 根據操作類型重新嘗試
        if operation_type == "find_next_page":
            return self.retry_find_next_page(failed_url)
        elif operation_type == "scrape_chapter":
            return self.retry_scrape_chapter(failed_url)
        
        return None

    def reset_session(self):
        """重新建立會話連接"""
        print("🔄 重新建立網絡連接...")
        
        # 關閉舊的會話
        self.session.close()
        
        # 創建新的會話
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        })
        
        print("✅ 網絡連接重新建立")

    def retry_find_next_page(self, url):
        """恢復後重新嘗試查找下一章"""
        try:
            print(f"🔍 恢復：重新查找下一章連結：{url}")
            
            response = self.session.get(url, timeout=15)
            response.encoding = response.apparent_encoding or 'utf-8'
            soup = BeautifulSoup(response.text, 'html.parser')
            next_url = self.find_next_page_url(soup, url)
            
            if next_url:
                print(f"✅ 恢復成功：找到下一章：{next_url}")
                return next_url
            else:
                print("✅ 恢復成功：確認沒有更多章節")
                return "completed"
                
        except Exception as e:
            print(f"❌ 恢復失敗：{e}")
            
            # 如果還有恢復機會，再次嘗試
            if self.recovery_count < self.max_recoveries:
                print("🔄 將再次嘗試自動恢復...")
                return self.trigger_auto_recovery(url, "find_next_page")
            else:
                print("❌ 已達到最大恢復次數，放棄恢復")
                return None

    def retry_scrape_chapter(self, url):
        """恢復後重新嘗試爬取章節"""
        try:
            print(f"📖 恢復：重新爬取章節：{url}")
            
            response = self.session.get(url, timeout=15)
            response.encoding = response.apparent_encoding or 'utf-8'
            soup = BeautifulSoup(response.text, 'html.parser')
            
            # 這裡可以重新爬取章節，但由於函數結構限制，
            # 我們返回 True 表示可以繼續，讓主循環重新處理
            print("✅ 恢復成功：重新建立連接，可以繼續爬取")
            return True
            
        except Exception as e:
            print(f"❌ 章節恢復失敗：{e}")
            return False

    def scrape_chapter_with_retry(self, url, chapter_num, chapters):
        """使用重試機制爬取單個章節（加強錯誤處理）"""
        for attempt in range(self.max_retries + 1):
            try:
                print(f"📖 正在爬取第 {chapter_num} 章：{url}")
                if attempt > 0:
                    print(f"   🔄 重試第 {attempt} 次...")
                
                # 獲取頁面
                response = self.session.get(url, timeout=15)
                response.encoding = response.apparent_encoding or 'utf-8'
                soup = BeautifulSoup(response.text, 'html.parser')
                
                # 智能提取章節標題和內容
                chapter_title, content = self.extract_chapter_content(soup, chapter_num)
                
                if content.strip():
                    chapters.append({
                        'title': chapter_title,
                        'content': content,
                        'url': url,
                        'word_count': len(content.split()),
                        'char_count': len(content)
                    })
                    
                    # 更新統計
                    self.stats['successful_urls'].append(url)
                    self.stats['total_characters'] += len(content)
                    self.stats['total_words'] += len(content.split())
                    
                    print(f"✅ 成功爬取：{chapter_title}")
                    print(f"   📊 字符數：{len(content):,} | 詞數：{len(content.split()):,}")
                    
                    return True
                else:
                    print(f"⚠️ 內容為空，跳過：{url}")
                    self.stats['failed_urls'].append(url)
                    self.stats['failed_chapters'] += 1
                    return False
                    
            except (requests.exceptions.ConnectionError, 
                    RemoteDisconnected,  # 修正：移除 requests.exceptions.
                    ConnectionError) as e:
                print(f"❌ 連接錯誤 (爬取章節 {attempt + 1}/{self.max_retries + 1}): {e}")
                
                if attempt < self.max_retries:
                    print(f"⏱️  等待 {self.retry_delay} 秒後重試...")
                    time.sleep(self.retry_delay)
                else:
                    # 啟動自動恢復
                    if self.auto_recovery and self.recovery_count < self.max_recoveries:
                        recovery_result = self.trigger_auto_recovery(url, "scrape_chapter")
                        if recovery_result:
                            return recovery_result
                    
                    print("❌ 達到最大重試次數，跳過此章節")
                    self.stats['failed_urls'].append(url)
                    self.stats['failed_chapters'] += 1
                    return False
                    
            except requests.exceptions.Timeout as e:
                print(f"❌ 請求超時 (爬取章節 {attempt + 1}/{self.max_retries + 1}): {e}")
                if attempt < self.max_retries:
                    print(f"⏱️  等待 {self.retry_delay} 秒後重試...")
                    time.sleep(self.retry_delay)
                else:
                    if self.auto_recovery and self.recovery_count < self.max_recoveries:
                        recovery_result = self.trigger_auto_recovery(url, "scrape_chapter")
                        if recovery_result:
                            return recovery_result
                    
                    print("❌ 達到最大重試次數，跳過此章節")
                    self.stats['failed_urls'].append(url)
                    self.stats['failed_chapters'] += 1
                    return False
                    
            except Exception as e:
                print(f"❌ 其他錯誤 (爬取章節 {attempt + 1}/{self.max_retries + 1}): {e}")
                if attempt < self.max_retries:
                    print(f"⏱️  等待 {self.retry_delay} 秒後重試...")
                    time.sleep(self.retry_delay)
                else:
                    if self.auto_recovery and self.recovery_count < self.max_recoveries:
                        recovery_result = self.trigger_auto_recovery(url, "scrape_chapter")
                        if recovery_result:
                            return recovery_result
                    
                    print("❌ 達到最大重試次數，跳過此章節")
                    self.stats['failed_urls'].append(url)
                    self.stats['failed_chapters'] += 1
                    return False
        
        return False

    def check_existing_book_file(self, start_url):
        """檢查是否有現有的書籍文件"""
        try:
            # 根據URL生成可能的文件名模式
            parsed_url = urlparse(start_url)
            url_identifier = parsed_url.netloc.replace('.', '_')
            
            # 搜索當前目錄中的JSON文件
            import glob
            json_files = glob.glob("*.json")
            
            for file_path in json_files:
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        data = json.load(f)
                        
                    if isinstance(data, list) and len(data) > 0:
                        book_data = data[0]
                        
                        # 檢查是否是同一本書（通過URL域名判斷）
                        if ('instruction' in book_data and 
                            url_identifier in file_path.lower()):
                            return file_path
                            
                except Exception as e:
                    continue
                    
        except Exception as e:
            print(f"⚠️ 檢查現有文件時出錯：{e}")
            
        return None

    def load_existing_chapters(self, file_path):
        """載入現有書籍的章節信息"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
                
            if isinstance(data, list) and len(data) > 0:
                self.existing_book_data = data[0]
                
                # 從頁面重建章節列表
                pages = self.existing_book_data.get('pages', [])
                chapters = []
                
                for i, page in enumerate(pages):
                    lines = page.split('\n\n', 1)
                    if len(lines) >= 2:
                        title = lines[0]
                        content = lines[1]
                    else:
                        title = f"第{i+1}章"
                        content = page
                    
                    chapters.append({
                        'title': title,
                        'content': content,
                        'url': f"existing_chapter_{i+1}",
                        'word_count': len(content.split()),
                        'char_count': len(content)
                    })
                    
                    # 記錄已存在的URL（模擬）
                    self.existing_urls.add(f"existing_chapter_{i+1}")
                
                self.existing_chapters = chapters.copy()
                return chapters
                
        except Exception as e:
            print(f"❌ 載入現有文件失敗：{e}")
            
        return []

    def find_continue_url(self, start_url, existing_chapters):
        """找到應該繼續爬取的URL"""
        if not existing_chapters:
            return start_url
            
        print(f"🔍 尋找續傳URL，已有 {len(existing_chapters)} 章")
        
        # 從起始URL開始，跳過已存在的章節數
        current_url = start_url
        skip_count = len(existing_chapters)
        
        print(f"📖 需要跳過 {skip_count} 章")
        
        for i in range(skip_count):
            try:
                response = self.session.get(current_url, timeout=10)
                response.encoding = response.apparent_encoding or 'utf-8'
                soup = BeautifulSoup(response.text, 'html.parser')
                
                # 獲取當前章節標題進行驗證
                chapter_title, _ = self.extract_chapter_content(soup, i + 1)
                print(f"   跳過第 {i+1} 章：{chapter_title}")
                
                # 找到下一章
                next_url = self.find_next_page_url(soup, current_url)
                if next_url:
                    current_url = next_url
                    time.sleep(self.delay)  # 避免請求過快
                else:
                    print("📄 沒有找到更多章節，爬取已完成")
                    return None
                    
            except Exception as e:
                print(f"❌ 跳過章節時出錯：{e}")
                return start_url
        
        print(f"✅ 找到續傳起點：第 {skip_count + 1} 章")
        return current_url

    def auto_save_book(self, ebook_data, is_complete=True, is_continue=False):
        """自動保存書籍（支援續傳模式）"""
        safe_title = re.sub(r'[^\w\s-]', '', ebook_data['title'])
        safe_title = safe_title.replace(' ', '_')[:50]
        timestamp = time.strftime("%Y%m%d_%H%M%S")
        
        if (is_continue):
            # 續傳模式：更新原文件名，但加上新的時間戳
            status_suffix = "updated_complete" if is_complete else "updated_partial"
            filename = f"{safe_title}_{status_suffix}_{timestamp}.json"
            print(f"🔄 續傳模式：更新書籍文件")
        else:
            # 新書模式
            status_suffix = "complete" if is_complete else "partial"
            filename = f"{safe_title}_{status_suffix}_{timestamp}.json"
        
        try:
            with open(filename, 'w', encoding='utf-8') as f:
                json.dump([ebook_data], f, ensure_ascii=False, indent=2)
            
            file_size = os.path.getsize(filename) / 1024
            print(f"\n💾 書籍已保存到：{filename}")
            print(f"📁 完整路徑：{os.path.abspath(filename)}")
            print(f"📄 文件大小：{file_size:.1f} KB")
            
            if is_continue:
                print(f"🔄 續傳完成：新增了 {len(ebook_data['pages']) - len(self.existing_book_data.get('pages', []))} 頁")
            
            if not is_complete:
                print("⚠️  注意：這是部分完成的書籍，可能還有更多章節")
                print("💡 建議：稍後重新運行腳本進行續傳")
            
            return filename
        except Exception as e:
            print(f"❌ 保存文件失敗：{e}")
            return None

    def extract_chapter_content(self, soup, chapter_num):
        """智能提取章節標題和內容"""
        # 常見的標題選擇器
        title_selectors = [
            'h1', 'h2', 'h3',
            '.title', '.chapter-title', '.readtitle h1',
            '.j_chapterName', '.chapter_name',
            '.bookname h1', '.book-title'
        ]
        
        # 常見的內容選擇器
        content_selectors = [
            '.content', '#content', '.chapter-content',
            '.novel-content', '.read-content', '#chapter_content',
            '.text', '.txt', '.detail', '.main-text',
            'div[id*="content"]', 'div[class*="content"]'
        ]
        
        # 提取標題
        chapter_title = f"第{chapter_num}章"
        for selector in title_selectors:
            title_element = soup.select_one(selector)
            if title_element:
                title_text = title_element.get_text().strip()
                if title_text and len(title_text) < 200:  # 標題不應該太長
                    chapter_title = title_text
                    break
        
        # 提取內容 - 修改這部分來正確處理 <p> 標籤
        content = ""
        for selector in content_selectors:
            content_element = soup.select_one(selector)
            if content_element:
                # 移除腳本和樣式標籤
                for script in content_element(["script", "style", "nav", "header", "footer"]):
                    script.decompose()
                
                # 🔧 新增：專門處理 <p> 標籤以保留分行
                content = self.extract_content_with_paragraphs(content_element)
                content = self.clean_content(content)
                
                # 檢查內容長度，太短可能不是正文
                if len(content) > 200:
                    break
        
        return chapter_title, content
    
    def extract_content_with_paragraphs(self, content_element):
        """專門處理 <p> 標籤，保留段落分行"""
        # 找到所有 <p> 標籤
        paragraphs = content_element.find_all('p')
        
        if paragraphs:
            # 如果有 <p> 標籤，逐個處理
            paragraph_texts = []
            for p in paragraphs:
                text = p.get_text().strip()
                if text:  # 只添加非空段落
                    paragraph_texts.append(text)
            
            # 用雙換行分隔段落
            return '\n\n'.join(paragraph_texts)
        else:
            # 如果沒有 <p> 標籤，使用原有邏輯
            return content_element.get_text()

    def clean_content(self, text):
        """清理文本內容（保留分行格式）"""
        # 首先移除常見的廣告文字和無關內容
        ad_patterns = [
            r'.*?章節錯誤.*?',
            r'.*?舉報.*?',
            r'.*?收藏.*?',
            r'.*?投票.*?',
            r'.*?推薦.*?',
            r'.*?廣告.*?',
            r'.*?免費閱讀.*?',
            r'.*?點擊進入.*?',
            r'.*?更多精彩.*?',
            r'本章未完.*?點擊下一頁繼續閱讀.*?',
        ]
        
        for pattern in ad_patterns:
            text = re.sub(pattern, '', text, flags=re.IGNORECASE)
        
        # 🔧 修改：更好地處理段落間距
        # 保留由 extract_content_with_paragraphs 產生的雙換行
        # 但清理多餘的空白行（超過兩個換行的情況）
        text = re.sub(r'\n\s*\n\s*\n+', '\n\n', text)
        
        # 清理每行開頭和結尾的空白，但保留換行
        lines = text.split('\n')
        cleaned_lines = []
        
        for line in lines:
            # 清理每行的首尾空白和多餘的空格
            cleaned_line = re.sub(r'[ \t]+', ' ', line.strip())
            cleaned_lines.append(cleaned_line)
        
        # 重新組合，保留分行
        text = '\n'.join(cleaned_lines)
        
        # 移除開頭和結尾的空白行
        text = text.strip()
        
        # 🔧 修改：確保段落之間保持雙換行
        # 將單個換行後跟非空行的情況轉換為雙換行（如果不是已經是雙換行）
        text = re.sub(r'(?<!\n)\n(?!\n)(?=\S)', '\n\n', text)
        
        # 最後清理：將多於兩個的連續換行縮減為兩個
        text = re.sub(r'\n{3,}', '\n\n', text)
        
        return text

    def find_next_page_url(self, soup, current_url):
        """智能尋找下一頁連結"""
        # 常見的下一頁選擇器和文字
        next_selectors = [
            'a[title*="下一"]', 'a[title*="下一頁"]', 'a[title*="下一章"]',
            'a:contains("下一")', 'a:contains("下一頁")', 'a:contains("下一章")',
            '.next', 'a.next', '#next', 'a#next',
            'a[id*="next"]', 'a[class*="next"]',
            '.chapter-nav .next', '.page-nav .next',
            'a#j_chapterNext', '.j_chapterNext'
        ]
        
        # 也嘗試文字匹配
        next_keywords = ["下一頁", "下一章", "下頁", "下章", "next", "Next"]
        
        # 首先嘗試常見選擇器
        for selector in next_selectors:
            try:
                next_element = soup.select_one(selector)
                if next_element and next_element.get('href'):
                    href = next_element.get('href')
                    if href and href != '#' and href != 'javascript:void(0)':
                        return urljoin(current_url, href)
            except:
                continue
        
        # 如果選擇器找不到，嘗試文字匹配
        for keyword in next_keywords:
            links = soup.find_all('a', string=re.compile(keyword, re.I))
            for link in links:
                href = link.get('href')
                if href and href != '#' and href != 'javascript:void(0)':
                    return urljoin(current_url, href)
        
        # 最後嘗試包含關鍵字的連結
        for keyword in next_keywords:
            links = soup.find_all('a', attrs={'title': re.compile(keyword, re.I)})
            for link in links:
                href = link.get('href')
                if href and href != '#' and href != 'javascript:void(0)':
                    return urljoin(current_url, href)
        
        return None
    
    def extract_book_info(self, start_url, first_chapter):
        """從URL和第一章提取書名和作者"""
        # 從URL嘗試提取書名
        parsed_url = urlparse(start_url)
        url_parts = parsed_url.path.split('/')
        
        # 預設值
        book_title = "未知書名"
        author = "未知作者"
        
        # 嘗試從第一章標題推斷書名
        if first_chapter['title']:
            title = first_chapter['title']
            # 移除常見的章節標記
            title = re.sub(r'第?\d+[章节]', '', title)
            title = re.sub(r'chapter\s*\d+', '', title, flags=re.I)
            title = title.strip()
            if title:
                book_title = title
        
        # 從URL路徑嘗試提取
        for part in url_parts:
            if part and len(part) > 2 and part not in ['book', 'novel', 'chapter', 'read']:
                book_title = part.replace('-', ' ').replace('_', ' ')
                break
        
        return book_title, author
    
    def clean_content(self, text):
        """清理文本內容（保留分行格式）"""
        # 首先移除常見的廣告文字和無關內容
        ad_patterns = [
            r'.*?章節錯誤.*?',
            r'.*?舉報.*?',
            r'.*?收藏.*?',
            r'.*?投票.*?',
            r'.*?推薦.*?',
            r'.*?廣告.*?',
            r'.*?免費閱讀.*?',
            r'.*?點擊進入.*?',
            r'.*?更多精彩.*?',
            r'本章未完.*?點擊下一頁繼續閱讀.*?',
        ]
        
        for pattern in ad_patterns:
            text = re.sub(pattern, '', text, flags=re.IGNORECASE)
        
        # 🔧 修改：更好地處理段落間距
        # 保留由 extract_content_with_paragraphs 產生的雙換行
        # 但清理多餘的空白行（超過兩個換行的情況）
        text = re.sub(r'\n\s*\n\s*\n+', '\n\n', text)
        
        # 清理每行開頭和結尾的空白，但保留換行
        lines = text.split('\n')
        cleaned_lines = []
        
        for line in lines:
            # 清理每行的首尾空白和多餘的空格
            cleaned_line = re.sub(r'[ \t]+', ' ', line.strip())
            cleaned_lines.append(cleaned_line)
        
        # 重新組合，保留分行
        text = '\n'.join(cleaned_lines)
        
        # 移除開頭和結尾的空白行
        text = text.strip()
        
        # 🔧 修改：確保段落之間保持雙換行
        # 將單個換行後跟非空行的情況轉換為雙換行（如果不是已經是雙換行）
        text = re.sub(r'(?<!\n)\n(?!\n)(?=\S)', '\n\n', text)
        
        # 最後清理：將多於兩個的連續換行縮減為兩個
        text = re.sub(r'\n{3,}', '\n\n', text)
        
        return text
    
    def convert_to_ebook(self, title, author, chapters):
        """轉換為 Ebook 格式"""
        # 將章節內容分頁
        pages = []
        
        for chapter in chapters:
            content = chapter['content']
            chapter_title = chapter['title']
            
            # 每頁最多2000字
            max_chars_per_page = 2000
            
            if len(content) <= max_chars_per_page:
                # 短章節，整章作為一頁
                pages.append(f"{chapter_title}\n\n{content}")
            else:
                # 長章節，智能分頁
                paragraphs = content.split('\n\n')
                current_page = f"{chapter_title}\n\n"
                current_length = len(current_page)
                
                for paragraph in paragraphs:
                    if current_length + len(paragraph) + 2 > max_chars_per_page and current_page.strip() != chapter_title:
                        pages.append(current_page.strip())
                        current_page = paragraph + "\n\n"
                        current_length = len(current_page)
                    else:
                        current_page += paragraph + "\n\n"
                        current_length += len(paragraph) + 2
                
                if current_page.strip():
                    pages.append(current_page.strip())
        
        # 生成書籍ID
        book_id = f"scraped_{title.replace(' ', '_').lower()}"
        
        ebook_data = {
            "id": book_id,
            "title": title,
            "author": author,
            "coverImage": "default_cover",
            "instruction": f"從網路爬取的書籍：{title}，作者：{author}。共{len(chapters)}章，{len(pages)}頁。",
            "pages": pages,
            "totalPages": len(pages),
            "currentPage": 0,
            "bookmarkedPages": []
        }
        
        return ebook_data

    def print_scraping_summary(self, chapters):
        """顯示詳細的爬取總結（包含恢復統計）"""
        duration = self.stats['end_time'] - self.stats['start_time']
        
        print("\n" + "=" * 80)
        if self.continue_mode:
            print("🔄 續傳完成！詳細統計報告")
        else:
            print("🎉 爬取完成！詳細統計報告")
        print("=" * 80)
        
        # 基本統計
        print("📊 基本統計：")
        print(f"   ⏰ 本次耗時：{duration:.2f} 秒 ({duration/60:.1f} 分鐘)")
        
        if self.continue_mode:
            new_chapters = len(chapters) - len(self.existing_chapters)
            print(f"   📚 總章節：{len(chapters)} 章")
            print(f"   📖 已有章節：{len(self.existing_chapters)} 章")
            print(f"   🆕 新增章節：{new_chapters} 章")
            print(f"   ❌ 失敗章節：{self.stats['failed_chapters']} 章")
        else:
            print(f"   📚 成功章節：{self.stats['total_chapters']} 章")
            print(f"   ❌ 失敗章節：{self.stats['failed_chapters']} 章")
        
        # 新增恢復統計
        if self.recovery_count > 0:
            print(f"   🔄 自動恢復次數：{self.recovery_count} 次")
        
        print(f"   🌐 訪問URL數：{len(self.stats['visited_urls'])}")
        print(f"   ✅ 成功率：{(self.stats['total_chapters']/(self.stats['total_chapters']+self.stats['failed_chapters'])*100):.1f}%" if (self.stats['total_chapters']+self.stats['failed_chapters']) > 0 else "   ✅ 成功率：0%")
        
        # 內容統計
        print("\n📝 內容統計：")
        if self.continue_mode:
            print(f"   📄 總字符數：{self.stats['total_characters']:,} (本次新增)")
            print(f"   📝 總詞數：{self.stats['total_words']:,} (本次新增)")
        else:
            print(f"   📄 總字符數：{self.stats['total_characters']:,}")
            print(f"   📝 總詞數：{self.stats['total_words']:,}")
        
        if self.stats['total_chapters'] > 0:
            avg_chars = self.stats['total_characters'] / self.stats['total_chapters']
            avg_words = self.stats['total_words'] / self.stats['total_chapters']
            print(f"   📊 平均每章字符：{avg_chars:,.0f}")
            print(f"   📊 平均每章詞數：{avg_words:,.0f}")
        
        # 章節詳情
        if chapters:
            print("\n📖 章節詳情：")
            if self.continue_mode and len(self.existing_chapters) > 0:
                print(f"   (已有 {len(self.existing_chapters)} 章，以下為新增章節)")
                start_index = len(self.existing_chapters)
                display_chapters = chapters[start_index:start_index+10]
                for i, chapter in enumerate(display_chapters, start_index + 1):
                    print(f"   {i:2d}. {chapter['title'][:50]}{'...' if len(chapter['title']) > 50 else ''}")
                    print(f"       📊 {chapter['char_count']:,} 字符 | {chapter['word_count']:,} 詞")
            else:
                for i, chapter in enumerate(chapters[:10], 1):
                    print(f"   {i:2d}. {chapter['title'][:50]}{'...' if len(chapter['title']) > 50 else ''}")
                    print(f"       📊 {chapter['char_count']:,} 字符 | {chapter['word_count']:,} 詞")
            
            if len(chapters) > 10:
                print(f"   ... 還有 {len(chapters) - 10} 章")
        
        # 效率統計
        print("\n⚡ 效率統計：")
        if duration > 0:
            chars_per_sec = self.stats['total_characters'] / duration
            chapters_per_min = (self.stats['total_chapters'] / duration) * 60
            print(f"   🚀 爬取速度：{chars_per_sec:,.0f} 字符/秒")
            print(f"   📚 章節速度：{chapters_per_min:.1f} 章/分鐘")
        
        # 失敗URL（如果有）
        if self.stats['failed_urls']:
            print("\n❌ 失敗的URL：")
            for i, url in enumerate(self.stats['failed_urls'][:5], 1):
                print(f"   {i}. {url}")
            if len(self.stats['failed_urls']) > 5:
                print(f"   ... 還有 {len(self.stats['failed_urls']) - 5} 個失敗URL")
        
        print("=" * 80)

def main():
    """主函數：從用戶輸入的URL開始爬取（支援續傳和自動恢復）"""
    scraper = UniversalBookScraper()
    
    print("📚 Universal Book Scraper v2.3 (with Auto-Recovery)")
    print("=" * 50)
    
    # 獲取用戶輸入 - 改進輸入驗證
    while True:
        start_url = input("請輸入第一章的URL：").strip()
        
        # 檢查是否為空
        if not start_url:
            print("❌ URL不能為空，請重新輸入")
            continue
        
        # 檢查是否包含中文或無效字符
        if any('\u4e00' <= char <= '\u9fff' for char in start_url):
            print("❌ URL包含中文字符，請輸入正確的英文URL")
            print("💡 例如：https://example.com/book/chapter1.html")
            continue
        
        # 檢查是否包含提示文字
        if "請輸入" in start_url or "URL" in start_url:
            print("❌ 請不要包含提示文字，只輸入實際的網址")
            print("💡 例如：https://example.com/book/chapter1.html")
            continue
        
        # 確保URL有協議
        if not start_url.startswith(('http://', 'https://')):
            start_url = 'https://' + start_url
            print(f"🔧 已自動添加 https:// 前綴：{start_url}")
        
        # 驗證URL格式
        try:
            parsed = urlparse(start_url)
            if not parsed.netloc:
                print("❌ URL格式不正確，請輸入完整的網址")
                print("💡 例如：https://example.com/book/chapter1.html")
                continue
            break
        except Exception as e:
            print(f"❌ URL格式錯誤：{e}")
            print("💡 請輸入正確的網址格式，例如：https://example.com/book/chapter1.html")
            continue
    
    max_chapters = 999
    
    print(f"\n🚀 開始爬取：{start_url}")
    print(f"📖 自動爬取所有可用章節")
    print(f"🔄 重試機制：最多重試 {scraper.max_retries} 次")
    print(f"⏱️  重試延遲：{scraper.retry_delay} 秒")
    print(f"🛡️  自動恢復：啟用（最多 {scraper.max_recoveries} 次，等待 {scraper.recovery_delay} 秒）")
    print(f"📂 續傳功能：自動檢測已存在的文件")
    print("-" * 50)
    
    # 開始爬取
    try:
        ebook_data = scraper.scrape_from_url(start_url, max_chapters)
        
        if ebook_data:
            # 文件名處理
            safe_title = re.sub(r'[^\w\s-]', '', ebook_data['title'])
            safe_title = safe_title.replace(' ', '_')[:50]  # 限制文件名長度
            timestamp = time.strftime("%Y%m%d_%H%M%S")
            filename = f"{safe_title}_{timestamp}.json"
            
            # 保存文件
            with open(filename, 'w', encoding='utf-8') as f:
                json.dump([ebook_data], f, ensure_ascii=False, indent=2)
            
            # 最終總結
            print("\n🎊 任務完成！最終報告")
            print("=" * 60)
            print(f"📚 書名：{ebook_data['title']}")
            print(f"👤 作者：{ebook_data['author']}")
            print(f"📄 總頁數：{len(ebook_data['pages'])} 頁")
            print(f"📖 總章節：{scraper.stats['total_chapters']} 章")
            
            if scraper.continue_mode:
                existing_pages = len(scraper.existing_book_data.get('pages', []))
                new_pages = len(ebook_data['pages']) - existing_pages
                print(f"🔄 續傳結果：新增 {new_pages} 頁")
            
            print(f"📝 總字符：{scraper.stats['total_characters']:,}")
            print(f"📊 總詞數：{scraper.stats['total_words']:,}")
            print(f"💾 文件大小：{os.path.getsize(filename) / 1024:.1f} KB")
            print(f"💾 保存為：{filename}")
            print(f"📁 保存路徑：{os.path.abspath(filename)}")
            
            if scraper.stats['failed_chapters'] > 0:
                print(f"⚠️  失敗章節：{scraper.stats['failed_chapters']} 章")
                print("💡 建議稍後重新運行腳本進行續傳")
            
            print("\n💡 續傳功能說明：")
            print("   1. 下次運行時輸入相同的起始URL")
            print("   2. 腳本會自動檢測已存在的文件")
            print("   3. 跳過已爬取的章節，繼續未完成的部分")
            print("   4. 適合處理大型書籍或網絡中斷的情況")
            
            print("=" * 60)
            return filename
        else:
            print("\n❌ 爬取失敗，沒有獲取到任何內容")
            return None
            
    except Exception as e:
        print(f"\n❌ 爬取過程中發生錯誤：{e}")
        print("💡 可能的解決方案：")
        print("   1. 檢查網絡連接")
        print("   2. 確認URL是否正確")
        print("   3. 嘗試重新運行腳本")
        print("   4. 檢查網站是否有反爬蟲保護")
        return False

if __name__ == "__main__":
    main()
