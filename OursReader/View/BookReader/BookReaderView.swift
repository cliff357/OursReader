import SwiftUI

struct BookReaderView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) var dismiss
    @State var book: Ebook
    @State private var currentPageIndex = 0
    @State private var showControls = true
    @State private var showBookmarks = false
    @State private var progressPercentage: Double = 0
    @State private var isButtonActionInProgress = false
    
    // New states for push animation
    @State private var pageOffset: CGFloat = 0
    @State private var nextPageIndex: Int?
    @State private var animationDirection: PageTurnDirection?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                ColorManager.shared.background.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Top navigation bar when controls are visible
                    if showControls {
                        topControlBar()
                    }
                    
                    // Content area with animation - takes remaining space
                    ZStack {
                        // Current page
                        if !book.content.isEmpty && currentPageIndex < book.content.count {
                            pageView(for: currentPageIndex)
                                .offset(x: pageOffset)
                        }
                        
                        // Next page (during animation)
                        if let nextIdx = nextPageIndex, nextIdx >= 0, nextIdx < book.content.count {
                            pageView(for: nextIdx)
                                .offset(x: animationDirection == .next ? 
                                       geometry.size.width + pageOffset : 
                                       -geometry.size.width + pageOffset)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // Bottom indicator overlay
                VStack {
                    Spacer()
                    if showControls {
                        bottomPageIndicator()
                            .padding(.bottom, 20)
                    }
                }
                
                // Bookmarks sheet
                if showBookmarks {
                    bookmarkSheet()
                        .zIndex(2)
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
        .statusBar(hidden: !showControls)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                showControls.toggle()
            }
        }
    }
    
    // Page view for specific index
    private func pageView(for index: Int) -> some View {
        ScrollView {
            Text(book.content[index])
                .foregroundColor(.black)
                .padding()
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorManager.shared.background)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                showControls.toggle()
            }
        }
    }
    
    // Top navigation bar
    private func topControlBar() -> some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18))
                    .foregroundColor(.black)
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
                    .background(Color.gray.opacity(0.2))
                    .clipShape(Circle())
            }
            .buttonStyle(BorderlessButtonStyle())
            
            Spacer()
            
            // Bookmark button
            Button {
                toggleBookmark()
            } label: {
                Image(systemName: isCurrentPageBookmarked() ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 18))
                    .foregroundColor(.black)
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
                    .background(Color.gray.opacity(0.2))
                    .clipShape(Circle())
            }
            .buttonStyle(BorderlessButtonStyle())
            
            // Bookmarks list button
            Button {
                showBookmarks.toggle()
            } label: {
                Image(systemName: "list.bullet")
                    .font(.system(size: 18))
                    .foregroundColor(.black)
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
                    .background(Color.gray.opacity(0.2))
                    .clipShape(Circle())
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding()
        .background(ColorManager.shared.background.opacity(0.95))
    }
    
    // Bottom page indicator
    private func bottomPageIndicator() -> some View {
        HStack {
            Spacer()
            
            Text("\(currentPageIndex + 1) / \(book.totalPages)")
                .font(.system(size: 16))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(ColorManager.shared.background.opacity(0.8))
                .foregroundColor(.black)
                .cornerRadius(20)
                .shadow(color: .gray.opacity(0.3), radius: 2, x: 0, y: 1)
            
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
                        .foregroundColor(.black)
                    Spacer()
                    Button("Done") {
                        showBookmarks = false
                    }
                    .foregroundColor(.blue)
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
                                        .foregroundColor(.black)
                                    Spacer()
                                    Text("→")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .frame(height: 300)
            .background(ColorManager.shared.background)
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
    
    // Function to update progress percentage
    private func updateProgressPercentage() {
        if book.totalPages > 0 {
            progressPercentage = Double(currentPageIndex + 1) / Double(book.totalPages)
        } else {
            progressPercentage = 0
        }
    }
    
    // Page turn direction enum
    enum PageTurnDirection {
        case next
        case previous
    }
    
    // Turn page with animation
    private func turnPageWithAnimation(direction: PageTurnDirection) {
        guard !isButtonActionInProgress else { return }
        
        isButtonActionInProgress = true
        animationDirection = direction
        
        switch direction {
        case .next:
            if currentPageIndex < book.content.count - 1 {
                // Set up next page animation
                nextPageIndex = currentPageIndex + 1
                
                // Start the push animation
                withAnimation(.easeInOut(duration: 0.3)) {
                    pageOffset = -UIScreen.main.bounds.width
                }
                
                // After animation completes, update the page
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    currentPageIndex = nextPageIndex!
                    updateProgressPercentage()
                    
                    // Reset for next animation
                    pageOffset = 0
                    nextPageIndex = nil
                    animationDirection = nil
                    isButtonActionInProgress = false
                }
            } else {
                isButtonActionInProgress = false
            }
            
        case .previous:
            if currentPageIndex > 0 {
                // Set up previous page animation
                nextPageIndex = currentPageIndex - 1
                
                // Start the push animation
                withAnimation(.easeInOut(duration: 0.3)) {
                    pageOffset = UIScreen.main.bounds.width
                }
                
                // After animation completes, update the page
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    currentPageIndex = nextPageIndex!
                    updateProgressPercentage()
                    
                    // Reset for next animation
                    pageOffset = 0
                    nextPageIndex = nil
                    animationDirection = nil
                    isButtonActionInProgress = false
                }
            } else {
                isButtonActionInProgress = false
            }
        }
    }
    
    // Go to specific page with animation
    private func turnPageWithAnimation(to targetPage: Int) {
        guard !isButtonActionInProgress, 
              targetPage >= 0,
              targetPage < book.content.count, 
              targetPage != currentPageIndex else { return }
        
        // Determine direction based on target page
        let direction: PageTurnDirection = targetPage > currentPageIndex ? .next : .previous
        animationDirection = direction
        nextPageIndex = targetPage
        isButtonActionInProgress = true
        
        // Start the push animation
        withAnimation(.easeInOut(duration: 0.3)) {
            pageOffset = direction == .next ? -UIScreen.main.bounds.width : UIScreen.main.bounds.width
        }
        
        // After animation completes, update the page
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            currentPageIndex = targetPage
            updateProgressPercentage()
            
            // Reset for next animation
            pageOffset = 0
            nextPageIndex = nil
            animationDirection = nil
            isButtonActionInProgress = false
        }
    }
}

#Preview {
    BookReaderView(book: ebookList[0])
}
