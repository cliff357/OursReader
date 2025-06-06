import SwiftUI

struct BookDetailView: View {
    let book: Ebook
    @State private var showingReader = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Book cover image and title
                HStack(alignment: .top, spacing: 20) {
                    Image(book.coverImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 180)
                        .cornerRadius(8)
                        .shadow(radius: 5)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(book.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(ColorManager.shared.dark_brown2)
                        
                        Text("by \(book.author)")
                            .font(.subheadline)
                            .foregroundColor(ColorManager.shared.dark_brown)
                        
                        // Add reading progress indicator
                        if book.totalPages > 0 {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Reading Progress")
                                    .font(.caption)
                                    .foregroundColor(ColorManager.shared.dark_brown)
                                
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(ColorManager.shared.dark_brown.opacity(0.3))
                                        .frame(height: 6)
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(ColorManager.shared.red1)
                                        .frame(width: calculateProgressWidth(totalWidth: 120), height: 6)
                                }
                                
                                Text("\(book.currentPage + 1) of \(book.totalPages) pages")
                                    .font(.caption2)
                                    .foregroundColor(ColorManager.shared.dark_brown)
                            }
                            .padding(.top, 6)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showingReader = true
                        }) {
                            Text("Read Now")
                                .font(.headline)
                                .foregroundColor(ColorManager.shared.rice_white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(ColorManager.shared.red1)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal)
                
                Divider()
                    .background(ColorManager.shared.dark_brown.opacity(0.3))
                
                // Book description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                        .foregroundColor(ColorManager.shared.dark_brown2)
                    
                    Text(book.instruction)
                        .font(.body)
                        .foregroundColor(ColorManager.shared.dark_brown)
                }
                .padding(.horizontal)
                
                Divider()
                    .background(ColorManager.shared.dark_brown.opacity(0.3))
                
                // Book information
                VStack(alignment: .leading, spacing: 8) {
                    Text("Information")
                        .font(.headline)
                        .foregroundColor(ColorManager.shared.dark_brown2)
                    
                    HStack {
                        Text("Pages:")
                            .fontWeight(.medium)
                            .foregroundColor(ColorManager.shared.dark_brown2)
                        Text("\(book.totalPages)")
                            .foregroundColor(ColorManager.shared.dark_brown)
                        Spacer()
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(ColorManager.shared.background)
        .navigationTitle(book.name)
        .navigationBarTitleTextColor(ColorManager.shared.dark_brown2)
        .fullScreenCover(isPresented: $showingReader) {
            BookReaderView(book: book)
        }
    }
    
    // Calculate the width of the progress bar
    private func calculateProgressWidth(totalWidth: CGFloat) -> CGFloat {
        guard book.totalPages > 0 else { return 0 }
        let progress = CGFloat(book.currentPage + 1) / CGFloat(book.totalPages)
        return totalWidth * progress
    }
}

#Preview {
    NavigationView {
        BookDetailView(book: ebookList[0])
    }
}
