#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
PDF to Ebook JSON Converter
將 PDF 文件轉換為 OurReader app 的 JSON 格式
支援本地文件和網路 PDF URL
"""

import fitz  # PyMuPDF
import json
import time
import re
import os
import sys
import requests
from urllib.parse import urlparse, unquote
from pathlib import Path

class PDFToEbookConverter:
    def __init__(self):
        self.max_pages = 2000  # 最大處理頁數
        self.min_text_length = 30  # 最小文本長度
        self.max_chars_per_page = 1500  # 每頁最大字符數
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
        })
        
        # 統計信息
        self.stats = {
            'start_time': None,
            'end_time': None,
            'total_pages': 0,
            'processed_pages': 0,
            'total_chapters': 0,
            'total_characters': 0,
            'total_words': 0,
            'skipped_pages': 0
        }
    
    def convert_pdf_to_ebook(self, pdf_input, output_filename=None):
        """
        轉換 PDF 為 Ebook JSON 格式
        pdf_input: PDF 文件路徑或 URL
        output_filename: 輸出文件名（可選）
        """
        self.stats['start_time'] = time.time()
        
        print("📚 PDF to Ebook JSON Converter v1.0")
        print("=" * 60)
        
        try:
            # 檢測輸入類型並打開 PDF
            if pdf_input.startswith(('http://', 'https://')):
                print(f"🌐 從URL下載PDF：{pdf_input}")
                pdf_document = self._download_and_open_pdf(pdf_input)
                if not pdf_document:
                    return None
            else:
                print(f"📂 打開本地PDF：{pdf_input}")
                if not os.path.exists(pdf_input):
                    print(f"❌ 文件不存在：{pdf_input}")
                    return None
                pdf_document = fitz.open(pdf_input)
            
            # 獲取PDF信息
            metadata = pdf_document.metadata
            self.stats['total_pages'] = pdf_document.page_count
            
            print(f"📖 PDF信息：")
            print(f"   📄 總頁數：{self.stats['total_pages']}")
            print(f"   📝 標題：{metadata.get('title', '未知')}")
            print(f"   👤 作者：{metadata.get('author', '未知')}")
            print(f"   🏷️ 主題：{metadata.get('subject', '無')}")
            
            # 提取書籍信息
            book_info = self._extract_book_info(pdf_document, pdf_input, metadata)
            
            print(f"\n🔍 開始提取內容...")
            print(f"📊 處理限制：最多 {self.max_pages} 頁")
            print("-" * 60)
            
            # 提取章節
            chapters = self._extract_chapters_from_pdf(pdf_document)
            
            # 關閉PDF
            pdf_document.close()
            
            if not chapters:
                print("❌ 沒有提取到任何內容")
                return None
            
            # 轉換為 Ebook 格式
            ebook_data = self._convert_to_ebook_format(book_info, chapters)
            
            # 保存文件
            if not output_filename:
                safe_title = re.sub(r'[^\w\s-]', '', book_info['title'])
                safe_title = safe_title.replace(' ', '_')[:50]
                timestamp = time.strftime("%Y%m%d_%H%M%S")
                output_filename = f"{safe_title}_pdf_{timestamp}.json"
            
            self._save_ebook_json(ebook_data, output_filename)
            
            # 設定結束時間
            self.stats['end_time'] = time.time()
            
            # 顯示完成報告
            self._print_completion_report(ebook_data, output_filename)
            
            return output_filename
            
        except Exception as e:
            print(f"❌ 處理過程中出錯：{e}")
            return None
        
        finally:
            # 確保結束時間被設定（如果還沒有的話）
            if self.stats['end_time'] is None:
                self.stats['end_time'] = time.time()
    
    def _download_and_open_pdf(self, url):
        """下載並打開網路PDF"""
        try:
            print("   📥 正在下載PDF...")
            
            # 發送HEAD請求檢查文件大小
            head_response = self.session.head(url, timeout=10)
            content_length = head_response.headers.get('Content-Length')
            
            if content_length:
                file_size_mb = int(content_length) / (1024 * 1024)
                if file_size_mb > 100:  # 100MB 限制
                    print(f"⚠️ 文件太大（{file_size_mb:.1f}MB），可能需要很長時間")
                    confirm = input("是否繼續？(y/n): ").lower().strip()
                    if confirm != 'y':
                        return None
                
                print(f"   📊 文件大小：{file_size_mb:.1f}MB")
            
            # 下載PDF
            response = self.session.get(url, timeout=30)
            response.raise_for_status()
            
            # 檢查內容類型
            content_type = response.headers.get('Content-Type', '').lower()
            if 'pdf' not in content_type:
                print(f"⚠️ 警告：內容類型不是PDF ({content_type})")
            
            print("   ✅ 下載完成，正在打開PDF...")
            
            # 使用內存流打開PDF
            pdf_document = fitz.open(stream=response.content, filetype="pdf")
            return pdf_document
            
        except requests.exceptions.RequestException as e:
            print(f"❌ 下載失敗：{e}")
            return None
        except Exception as e:
            print(f"❌ 打開PDF失敗：{e}")
            return None
    
    def _extract_book_info(self, pdf_document, pdf_input, metadata):
        """提取書籍基本信息"""
        # ...existing code... (從元數據獲取信息)
        title = metadata.get('title', '').strip()
        author = metadata.get('author', '').strip()
        
        # ...existing code... (如果元數據沒有標題，嘗試從文件名提取)
        if not title:
            if pdf_input.startswith(('http://', 'https://')):
                parsed_url = urlparse(pdf_input)
                filename = unquote(os.path.basename(parsed_url.path))
            else:
                filename = os.path.basename(pdf_input)
            
            title = os.path.splitext(filename)[0]
            title = re.sub(r'[_-]', ' ', title)
            title = re.sub(r'\s+', ' ', title).strip()
        
        # ...existing code... (嘗試從第一頁提取標題)
        if not title or len(title) < 3:
            try:
                first_page = pdf_document[0]
                first_page_text = first_page.get_text()
                lines = [line.strip() for line in first_page_text.split('\n') if line.strip()]
                
                for line in lines[:10]:
                    if 5 <= len(line) <= 100 and not line.isdigit():
                        title = line
                        break
            except:
                pass
        
        if not title or len(title) < 3:
            title = "PDF書籍"
        
        if not author:
            author = "未知作者"
        
        return {
            'title': title,
            'author': author,
            'source': pdf_input
        }
    
    def _extract_chapters_from_pdf(self, pdf_document):
        """從PDF提取章節"""
        chapters = []
        current_chapter_content = ""
        current_chapter_title = "開始"
        chapter_count = 1
        
        max_pages_to_process = min(pdf_document.page_count, self.max_pages)
        
        for page_num in range(max_pages_to_process):
            try:
                page = pdf_document[page_num]
                page_text = page.get_text()
                
                cleaned_text = self._clean_pdf_text(page_text)
                
                if len(cleaned_text) < self.min_text_length:
                    self.stats['skipped_pages'] += 1
                    continue
                
                self.stats['processed_pages'] += 1
                
                potential_title = self._detect_chapter_title(cleaned_text)
                
                if potential_title and current_chapter_content.strip():
                    if self._is_valid_chapter_content(current_chapter_content):
                        chapters.append({
                            'title': current_chapter_title,
                            'content': current_chapter_content.strip(),
                            'page_start': page_num - 1,
                            'page_end': page_num,
                            'char_count': len(current_chapter_content),
                            'word_count': len(current_chapter_content.split())
                        })
                        
                        self.stats['total_characters'] += len(current_chapter_content)
                        self.stats['total_words'] += len(current_chapter_content.split())
                    
                    current_chapter_title = potential_title
                    current_chapter_content = cleaned_text
                    chapter_count += 1
                    
                    print(f"📖 發現第 {len(chapters) + 1} 章：{potential_title}")
                    
                else:
                    if current_chapter_content:
                        current_chapter_content += "\n\n" + cleaned_text
                    else:
                        current_chapter_content = cleaned_text
                
                if (page_num + 1) % 50 == 0:
                    progress = ((page_num + 1) / max_pages_to_process) * 100
                    print(f"📄 處理進度：{page_num + 1}/{max_pages_to_process} ({progress:.1f}%) - 已找到 {len(chapters)} 章")
                
            except Exception as e:
                print(f"⚠️ 處理第 {page_num + 1} 頁時出錯：{e}")
                self.stats['skipped_pages'] += 1
                continue
        
        if current_chapter_content.strip() and self._is_valid_chapter_content(current_chapter_content):
            chapters.append({
                'title': current_chapter_title,
                'content': current_chapter_content.strip(),
                'page_start': 0,
                'page_end': max_pages_to_process - 1,
                'char_count': len(current_chapter_content),
                'word_count': len(current_chapter_content.split())
            })
            
            self.stats['total_characters'] += len(current_chapter_content)
            self.stats['total_words'] += len(current_chapter_content.split())
        
        self.stats['total_chapters'] = len(chapters)
        
        print(f"\n✅ 章節提取完成：共 {len(chapters)} 章")
        return chapters
    
    def _clean_pdf_text(self, text):
        """清理PDF提取的文本"""
        text = re.sub(r'([a-z])([A-Z])', r'\1 \2', text)
        text = re.sub(r'([。！？])([a-zA-Z\u4e00-\u9fff])', r'\1\n\2', text)
        
        text = text.replace('\r\n', '\n').replace('\r', '\n')
        text = re.sub(r'[ \t]+', ' ', text)
        text = re.sub(r'\n+', '\n', text)
        
        lines = text.split('\n')
        cleaned_lines = []
        
        for line in lines:
            line = line.strip()
            
            if re.match(r'^[\d\s]+$', line) and len(line) < 10:
                continue
            
            if len(line) < 3:
                continue
            
            if self._is_header_footer(line):
                continue
            
            cleaned_lines.append(line)
        
        result = []
        current_paragraph = []
        
        for line in cleaned_lines:
            if (line.endswith(('。', '！', '？', '.', '!', '?')) and 
                len(line) > 20):
                current_paragraph.append(line)
                result.append(' '.join(current_paragraph))
                current_paragraph = []
            else:
                current_paragraph.append(line)
        
        if current_paragraph:
            result.append(' '.join(current_paragraph))
        
        return '\n\n'.join(result)
    
    def _is_header_footer(self, line):
        """判斷是否為頁眉頁腳"""
        patterns = [
            r'^第?\s*\d+\s*頁',
            r'^Page\s*\d+',
            r'Copyright\s*©',
            r'版權所有',
            r'www\.',
            r'http[s]?://',
            r'ISBN',
            r'出版社',
            r'^\d{4}年\d{1,2}月',
        ]
        
        for pattern in patterns:
            if re.search(pattern, line, re.I):
                return True
        
        return False
    
    def _detect_chapter_title(self, text):
        """檢測章節標題"""
        lines = text.split('\n')[:3]
        
        for line in lines:
            line = line.strip()
            
            patterns = [
                r'^第[一二三四五六七八九十\d]+[章節]',
                r'^Chapter\s+\d+',
                r'^[第]?[一二三四五六七八九十\d]+[章節]',
                r'^\d+\.\d*\s+',
                r'^\d+\s+',
            ]
            
            for pattern in patterns:
                if re.search(pattern, line, re.I):
                    if len(line) < 200:
                        return line
        
        return None
    
    def _is_valid_chapter_content(self, content):
        """判斷是否為有效的章節內容"""
        content = content.strip()
        
        if len(content) < 100:
            return False
        
        words = content.split()
        if len(words) < 30:
            return False
        
        text_chars = sum(1 for c in content if c.isalpha() or '\u4e00' <= c <= '\u9fff')
        if text_chars / len(content) < 0.3:
            return False
        
        return True
    
    def _convert_to_ebook_format(self, book_info, chapters):
        """轉換為 OurReader 的 Ebook JSON 格式"""
        pages = []
        
        print(f"\n📚 轉換為 Ebook 格式...")
        print(f"📊 最大每頁字符數：{self.max_chars_per_page}")
        
        for chapter in chapters:
            content = chapter['content']
            chapter_title = chapter['title']
            
            chapter_pages = self._split_chapter_into_pages(chapter_title, content)
            pages.extend(chapter_pages)
            
            print(f"   ✅ {chapter_title}: {len(chapter_pages)} 頁")
        
        book_id = f"pdf_{int(time.time())}_{hash(book_info['title']) % 10000}"
        
        ebook_data = {
            "id": book_id,
            "title": book_info['title'],
            "author": book_info['author'],
            "coverImage": "default_cover",
            "instruction": f"從PDF轉換的書籍：{book_info['title']}，作者：{book_info['author']}。原始來源：{book_info['source']}。共{len(chapters)}章，{len(pages)}頁。",
            "pages": pages,
            "totalPages": len(pages),
            "currentPage": 0,
            "bookmarkedPages": []
        }
        
        return ebook_data
    
    def _split_chapter_into_pages(self, chapter_title, content):
        """將章節內容智能分頁"""
        pages = []
        
        if len(content) <= self.max_chars_per_page:
            pages.append(f"{chapter_title}\n\n{content}")
        else:
            paragraphs = content.split('\n\n')
            current_page = f"{chapter_title}\n\n"
            current_length = len(current_page)
            
            for paragraph in paragraphs:
                if current_length + len(paragraph) + 2 > self.max_chars_per_page:
                    if current_page.strip() != chapter_title:
                        pages.append(current_page.rstrip())
                        current_page = paragraph + "\n\n"
                        current_length = len(current_page)
                    else:
                        if len(paragraph) > self.max_chars_per_page:
                            sentences = re.split(r'([。！？.!?])', paragraph)
                            temp_content = ""
                            
                            for i in range(0, len(sentences), 2):
                                if i + 1 < len(sentences):
                                    sentence = sentences[i] + sentences[i + 1]
                                else:
                                    sentence = sentences[i]
                                
                                if len(temp_content + sentence) > self.max_chars_per_page:
                                    if temp_content:
                                        pages.append(f"{chapter_title}\n\n{temp_content}")
                                        temp_content = sentence
                                    else:
                                        while sentence:
                                            chunk = sentence[:self.max_chars_per_page - len(chapter_title) - 4]
                                            pages.append(f"{chapter_title}\n\n{chunk}")
                                            sentence = sentence[len(chunk):]
                                else:
                                    temp_content += sentence
                            
                            if temp_content:
                                current_page = temp_content + "\n\n"
                                current_length = len(current_page) + len(chapter_title) + 2
                        else:
                            current_page += paragraph + "\n\n"
                            current_length += len(paragraph) + 2
                else:
                    current_page += paragraph + "\n\n"
                    current_length += len(paragraph) + 2
            
            if current_page.strip():
                pages.append(current_page.rstrip())
        
        return pages
    
    def _save_ebook_json(self, ebook_data, filename):
        """保存為JSON文件"""
        try:
            with open(filename, 'w', encoding='utf-8') as f:
                json.dump([ebook_data], f, ensure_ascii=False, indent=2)
            
            print(f"\n💾 文件已保存：{filename}")
            
        except Exception as e:
            print(f"❌ 保存文件失敗：{e}")
            raise
    
    def _print_completion_report(self, ebook_data, filename):
        """打印完成報告"""
        # 安全計算處理時間
        if self.stats['end_time'] and self.stats['start_time']:
            duration = self.stats['end_time'] - self.stats['start_time']
        else:
            duration = 0
        
        file_size = os.path.getsize(filename) / 1024
        
        print("\n" + "=" * 70)
        print("🎊 PDF轉換完成！詳細報告")
        print("=" * 70)
        
        print("📊 基本信息：")
        print(f"   📚 書名：{ebook_data['title']}")
        print(f"   👤 作者：{ebook_data['author']}")
        print(f"   🆔 書籍ID：{ebook_data['id']}")
        
        print("\n📈 處理統計：")
        if duration > 0:
            print(f"   ⏰ 處理時間：{duration:.2f} 秒 ({duration/60:.1f} 分鐘)")
        else:
            print(f"   ⏰ 處理時間：未知")
        print(f"   📄 PDF總頁數：{self.stats['total_pages']}")
        print(f"   ✅ 處理頁數：{self.stats['processed_pages']}")
        print(f"   ⏭️ 跳過頁數：{self.stats['skipped_pages']}")
        print(f"   📖 提取章節：{self.stats['total_chapters']}")
        print(f"   📑 Ebook頁數：{len(ebook_data['pages'])}")
        
        print("\n📝 內容統計：")
        print(f"   📄 總字符數：{self.stats['total_characters']:,}")
        print(f"   📝 總詞數：{self.stats['total_words']:,}")
        
        if self.stats['total_chapters'] > 0:
            avg_chars = self.stats['total_characters'] / self.stats['total_chapters']
            avg_words = self.stats['total_words'] / self.stats['total_chapters']
            print(f"   📊 平均每章字符：{avg_chars:,.0f}")
            print(f"   📊 平均每章詞數：{avg_words:,.0f}")
        
        print("\n💾 文件信息：")
        print(f"   📁 文件名：{filename}")
        print(f"   📁 完整路徑：{os.path.abspath(filename)}")
        print(f"   📊 文件大小：{file_size:.1f} KB")
        
        if duration > 0 and self.stats['processed_pages'] > 0:
            pages_per_min = (self.stats['processed_pages'] / duration) * 60
            chars_per_sec = self.stats['total_characters'] / duration
            print(f"\n⚡ 效率統計：")
            print(f"   🚀 處理速度：{pages_per_min:.1f} 頁/分鐘")
            print(f"   💨 字符速度：{chars_per_sec:,.0f} 字符/秒")
        
        print("\n✨ 使用說明：")
        print("   1. 將生成的JSON文件傳輸到iOS設備")
        print("   2. 在OurReader app中選擇「導入書籍」")
        print("   3. 選擇這個JSON文件進行導入")
        print("   4. 即可開始閱讀你的PDF書籍！")
        
        print("=" * 70)

def main():
    """主函數"""
    converter = PDFToEbookConverter()
    
    print("📚 PDF to Ebook JSON Converter")
    print("將PDF文件轉換為OurReader app的JSON格式")
    print("支援本地文件和網路PDF URL")
    print("=" * 60)
    
    while True:
        pdf_input = input("請輸入PDF文件路徑或URL（按Enter退出）：").strip()
        
        if not pdf_input:
            print("👋 再見！")
            break
        
        if pdf_input.startswith(('http://', 'https://')):
            print("🌐 檢測到URL，將從網路下載PDF")
        elif os.path.exists(pdf_input):
            print("📂 檢測到本地文件")
        else:
            print("❌ 文件不存在或URL無效，請重新輸入")
            continue
        
        print("\n⚙️ 處理設定（按Enter使用默認值）：")
        
        max_pages_input = input(f"最大處理頁數（默認{converter.max_pages}）：").strip()
        if max_pages_input.isdigit():
            converter.max_pages = int(max_pages_input)
        
        chars_per_page_input = input(f"每頁最大字符數（默認{converter.max_chars_per_page}）：").strip()
        if chars_per_page_input.isdigit():
            converter.max_chars_per_page = int(chars_per_page_input)
        
        output_name = input("自訂輸出文件名（不含.json，按Enter自動生成）：").strip()
        if output_name:
            output_name = output_name.replace('.json', '') + '.json'
        else:
            output_name = None
        
        print(f"\n🚀 開始處理...")
        
        result = converter.convert_pdf_to_ebook(pdf_input, output_name)
        
        if result:
            print(f"✅ 轉換成功！文件保存為：{result}")
            
            continue_choice = input("\n是否處理另一個PDF？(y/n): ").lower().strip()
            if continue_choice != 'y':
                break
        else:
            print("❌ 轉換失敗")
            retry = input("是否重試？(y/n): ").lower().strip()
            if retry != 'y':
                break
    
    print("\n🎊 感謝使用PDF轉Ebook工具！")

if __name__ == "__main__":
    try:
        import fitz
        import requests
    except ImportError as e:
        print("❌ 缺少必要的庫，請安裝：")
        print("pip install PyMuPDF requests")
        print(f"錯誤詳情：{e}")
        sys.exit(1)
    
    main()