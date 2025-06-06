import SwiftUI

struct BookReaderView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) var dismiss // Add dismiss environment value
    @State var book: Ebook
    @State private var currentPageIndex = 0
    @State private var showControls = true
    @State private var showBookmarks = false
    @State private var progressPercentage: Double = 0
    @State private var isButtonActionInProgress = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                Color(.systemBackground).edgesIgnoringSafeArea(.all)
                
                // Content area (text and page content)
                VStack(spacing: 0) {
                    // Only show top navigation when controls are visible
                    if showControls {
                        topControlBar()
                            .zIndex(1) // Ensure navbar is above other elements
                    }
                    
                    // Page content
                    if !book.content.isEmpty && currentPageIndex < book.content.count {
                        ScrollView {
                            Text(book.content[currentPageIndex])
                                .padding()
                                .padding(.bottom, 20)
                                .onTapGesture {
                                    // Only toggle controls when tapping on the text
                                    withAnimation {
                                        showControls.toggle()
                                    }
                                }
                        }
                    } else {
                        Text("No content available")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .onTapGesture {
                                withAnimation {
                                    showControls.toggle()
                                }
                            }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Bottom page indicator overlay
                VStack {
                    Spacer()
                    if showControls {
                        bottomPageIndicator()
                    }
                }
                .padding(.bottom, 20)
                
                // Bookmarks sheet
                if showBookmarks {
                    bookmarkSheet()
                        .zIndex(2) // Highest z-index to be above everything
                }
            }
            .onAppear {
                currentPageIndex = book.currentPage
                updateProgressPercentage()
            }
            .onDisappear {
                book.currentPage = currentPageIndex
            }
        }
        .gesture(
            DragGesture(minimumDistance: 50, coordinateSpace: .local)
                .onEnded({ value in
                    if value.translation.width > 0 {
                        // Swipe right (previous page)
                        if currentPageIndex > 0 {
                            turnPageWithAnimation(direction: .previous)
                        }
                    } else if value.translation.width < 0 {
                        // Swipe left (next page)
                        if currentPageIndex < book.content.count - 1 {
                            turnPageWithAnimation(direction: .next)
                        }
                    }
                })
        )
        .navigationBarHidden(true)
        .statusBar(hidden: !showControls) // Also hide status bar when controls are hidden
    }
    
    // Top navigation bar
    private func topControlBar() -> some View {
        HStack {
            Button {
                // Explicitly specify we don't want this to toggle controls
                // by using dismiss() directly without animation
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
                    .background(Color.gray.opacity(0.2))
                    .clipShape(Circle())
            }
            .buttonStyle(BorderlessButtonStyle()) // Important: use BorderlessButtonStyle instead
            
            Spacer()
            
//            HStack(spacing: 15) {
//                Text("\(currentPageIndex + 1)/\(book.totalPages)")
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//                    .padding(.horizontal, 4)
//                
//                Button {
//                    // Add a flag to prevent control toggle
//                    toggleBookmark()
//                } label: {
//                    Image(systemName: isCurrentPageBookmarked() ? "bookmark.fill" : "bookmark")
//                        .font(.system(size: 18))
//                        .foregroundColor(.primary)
//                        .frame(width: 44, height: 44)
//                        .contentShape(Circle())
//                        .background(Color.gray.opacity(0.2))
//                        .clipShape(Circle())
//                }
//                .buttonStyle(BorderlessButtonStyle()) // Important
//                
//                Button {
//                    // Use withAnimation but keep it separate from toggle controls
//                    withAnimation {
//                        showBookmarks.toggle()
//                    }
//                } label: {
//                    Image(systemName: "list.bullet")
//                        .font(.system(size: 18))
//                        .foregroundColor(.primary)
//                        .frame(width: 44, height: 44)
//                        .contentShape(Circle())
//                        .background(Color.gray.opacity(0.2))
//                        .clipShape(Circle())
//                }
//                .buttonStyle(BorderlessButtonStyle()) // Important
//            }
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.9))
    }
    
    // Bottom page indicator
    private func bottomPageIndicator() -> some View {
        HStack {
            Spacer()
            
            Text("\(currentPageIndex + 1) / \(book.totalPages)")
                .font(.system(size: 16))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.6))
                .foregroundColor(.white)
                .cornerRadius(20)
            
            Spacer()
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    // Bookmarks sheet
    private func bookmarkSheet() -> some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    showBookmarks = false
                }
            
            VStack {
                HStack {
                    Text("Bookmarks")
                        .font(.headline)
                    Spacer()
                    Button("Done") {
                        showBookmarks = false
                    }
                }
                .padding()
                
                Divider()
                
                if book.bookmarkedPages.isEmpty {
                    Text("No bookmarks yet")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    List {
                        ForEach(book.bookmarkedPages, id: \.self) { page in
                            Button(action: {
                                currentPageIndex = page
                                updateProgressPercentage()
                                showBookmarks = false
                            }) {
                                HStack {
                                    Text("Page \(page + 1)")
                                    Spacer()
                                    Text("→")
                                }
                            }
                        }
                    }
                }
            }
            .frame(height: 300)
            .background(Color(.systemBackground))
            .cornerRadius(15)
            .shadow(radius: 10)
            .padding()
            .transition(.move(edge: .bottom))
        }
    }
    
    // Function to check if current page is bookmarked
    private func isCurrentPageBookmarked() -> Bool {
        return book.bookmarkedPages.contains(currentPageIndex)
    }
    
    // Function to toggle bookmark for current page
    private func toggleBookmark() {
        if let index = book.bookmarkedPages.firstIndex(of: currentPageIndex) {
            book.bookmarkedPages.remove(at: index)
        } else {
            book.bookmarkedPages.append(currentPageIndex)
        }
    }
    
    // Function to update progress percentage (still needed for bookmarks)
    private func updateProgressPercentage() {
        if book.totalPages > 0 {
            progressPercentage = Double(currentPageIndex + 1) / Double(book.totalPages)
        } else {
            progressPercentage = 0
        }
    }
    
    // Add an enum for page turn direction
    private enum PageTurnDirection {
        case previous, next
    }
    
    // New consolidated page turn function to handle both animations
    private func turnPageWithAnimation(direction: PageTurnDirection) {
        guard !isButtonActionInProgress else { return }
        isButtonActionInProgress = true
        
        switch direction {
        case .next:
            if currentPageIndex < book.content.count - 1 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentPageIndex += 1
                    updateProgressPercentage()
                }
            }
        case .previous:
            if currentPageIndex > 0 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentPageIndex -= 1
                    updateProgressPercentage()
                }
            }
        }
        
        // Reset button action state after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isButtonActionInProgress = false
        }
    }
    
    // Go to specific page with animation
    private func turnPageWithAnimation(to targetPage: Int) {
        guard !isButtonActionInProgress, 
              targetPage >= 0,
              targetPage < book.content.count, 
              targetPage != currentPageIndex else { return }
        
        isButtonActionInProgress = true
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentPageIndex = targetPage
            updateProgressPercentage()
        }
        
        // Reset button action state after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isButtonActionInProgress = false
        }
    }
}

#Preview {
    BookReaderView(book: ebookList[0])
}
