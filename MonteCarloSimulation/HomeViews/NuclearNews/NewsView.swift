//
//  NewsView.swift
//  MonteCarloSimulation
//
//  Created by Mohammad Abusalha on 1/10/25.
//

import SwiftUI
import FeedKit
import WebKit
import SwiftSoup

struct NewsView_Preview: PreviewProvider{
    static var previews: some View {
        NewsView()
    }
}


struct NewsItem: Identifiable {
    let id = UUID()
    let title: String
    let pubDate: String?
    let link: String?
    var imageURL: String?  // Add this property to store the image URL
    var relatedLinks: String? = ""
    
    // Initialize from RSS feed item
    init(from feedItem: RSSFeedItem) {
        self.title = feedItem.title ?? "No Title"
        self.pubDate = feedItem.pubDate?.description
        self.link = feedItem.link
        // Assuming the RSS feed item includes an image URL (e.g., <media:content> or <enclosure>)
        self.imageURL = feedItem.media?.mediaBackLinks?.first as? String
        // Change this based on how image URL is provided in the RSS feed
    }
}

struct NewsView: View {
    @State private var newsItems: [(title: String, link: String, imageURL: String, pubDate: String)] = []
    
    var body: some View {
        NavigationView {
            VStack {
                List(newsItems, id: \.link) { item in
                    NavigationLink(destination: WebView(url: item.link)) {
                        HStack {
                            AsyncImage(url: URL(string: item.imageURL)) { image in
                                image.resizable()
                                    .scaledToFill()
                                    .frame(width: 50, height: 50)  // Adjust size as needed
                            } placeholder: {
                                ProgressView()  // Show a loading indicator until the image is loaded
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .frame(width: 25, height: 25)
                            }
                            .padding()
                            VStack(alignment: .leading) {
                                Text(item.title)
                                    .font(.headline)
                                Text(item.pubDate)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding()
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        // Fetch and display the logo from a URL
                        HStack {
                            Text("Latest Nuclear News")
                            AsyncImage(url: URL(string: "https://www.world-nuclear-news.org/images/wnn_logo.png")) { image in
                                image.resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)  // Adjust size as needed
                            } placeholder: {
                                ProgressView()  // Show a loading indicator until the image is loaded
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .frame(width: 150, height: 50)
                            }
                            Spacer()
                        }
                        
                    }
                }
                .onAppear {
                    fetchNews()
                }
            }
            
        }
    }
    func fetchNews() {
        let feedURL = URL(string: "https://www.world-nuclear-news.org/rss")!
        let parser = CustomRSSParser()
        DispatchQueue.global(qos: .background).async {
            parser.parse(feedURL: feedURL) { items in
                DispatchQueue.main.async {
                    self.newsItems = Array(items.prefix(5))
                }
            }
        }
    }

}

struct WebView: View {
    let url: String
    
    var body: some View {
        WebViewRepresentable(url: url)
            .edgesIgnoringSafeArea(.all)
    }
}

struct WebViewRepresentable: UIViewRepresentable {
    let url: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        if let validURL = URL(string: url) {
            let request = URLRequest(url: validURL)
            webView.load(request)
        }
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
