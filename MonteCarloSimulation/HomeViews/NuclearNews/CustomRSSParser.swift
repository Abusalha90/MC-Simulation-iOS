//
//  CustomRSSParser.swift
//  MonteCarloSimulation
//
//  Created by Mohammad Abusalha on 1/10/25.
//


import Foundation

class CustomRSSParser: NSObject, XMLParserDelegate {
    private var currentElement = ""
    private var currentTitle = ""
    private var currentLink = ""
    private var currentImageURL = ""
    private var currentPubDate = ""

    var newsItems: [(title: String, link: String, imageURL: String, pubDate: String)] = []
    
    func parse(feedURL: URL, completion: @escaping ([(title: String, link: String, imageURL: String, pubDate: String)]) -> Void) {
        let parser = XMLParser(contentsOf: feedURL)!
        parser.delegate = self
        parser.parse()
        completion(newsItems)
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if currentElement == "title" {
            currentTitle += trimmedString
        } else if currentElement == "link" {
            currentLink += trimmedString
        } else if currentElement == "wnn:articleImage" {
            currentImageURL += trimmedString
        } else if currentElement == "pubDate"{
            currentPubDate += trimmedString
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName: String?) {
        if elementName == "item" {
            newsItems.append((title: currentTitle, link: currentLink, imageURL: currentImageURL, pubDate: currentPubDate))
            currentTitle = ""
            currentLink = ""
            currentImageURL = ""
            currentPubDate = ""
        }
        currentElement = ""
    }
}
