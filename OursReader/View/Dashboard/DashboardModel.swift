//
//  DashboardModel.swift
//  OursReader
//
//  Created by Cliff Chan on 19/9/2024.
//

import Foundation
import SwiftUI

enum ButtonListType {
    case push_notification
    case widget
    case ebook
    
    var color: Color {
        switch self {
        case .push_notification:
            return ColorManager.shared.firstTab
        case .widget:
            return ColorManager.shared.secondTab
        case .ebook:
            return ColorManager.shared.thirdTab
        }
    }
}

// 定義 Widget 結構
struct Widget {
    var id: String
    var name: String
    var actionCode: String
}

// 定義 Ebook 結構
struct Ebook: Identifiable {
    let id: String
    let name: String
    let title: String
    let instruction: String
    
    // New properties
    var author: String = "Unknown Author"
    var coverImage: String = ""
    var content: [String] = [] // Each string represents a page
    var currentPage: Int = 0
    var totalPages: Int {
        return content.count
    }
    var bookmarkedPages: [Int] = []
}

let widgetList: [Widget] = [
    Widget(id: "widget_001", name: "Weather Widget", actionCode: "SHOW_WEATHER"),
    Widget(id: "widget_002", name: "Calendar Widget", actionCode: "OPEN_CALENDAR"),
    Widget(id: "widget_003", name: "Music Player Widget", actionCode: "PLAY_MUSIC"),
    Widget(id: "widget_004", name: "Stock Tracker Widget", actionCode: "SHOW_STOCKS")
]

// 建立 ebook list
let ebookList: [Ebook] = [
    Ebook(
        id: "ebook_001", 
        name: "Programming 101", 
        title: "Introduction to Programming", 
        instruction: "Learn the basics of programming languages.",
        author: "John Doe",
        coverImage: "default_cover", // 🔧 改為 default_cover，將由程式化生成
        content: [
            "Chapter 1: What is Programming?\n\nProgramming is the process of creating a set of instructions that tell a computer how to perform a task. Programming can be done using a variety of computer programming languages, such as JavaScript, Python, and C++. What is Programming?\n\nProgramming is the process of creating a set of instructions that tell a computer how to perform a task. Programming can be done using a variety of computer programming languages, such as JavaScript, Python, and C++.What is Programming?\n\nProgramming is the process of creating a set of instructions that tell a computer how to perform a task. Programming can be done using a variety of computer programming languages, such as JavaScript, Python, and C++.What is Programming?\n\nProgramming is the process of creating a set of instructions that tell a computer how to perform a task. Programming can be done using a variety of computer programming languages, such as JavaScript, Python, and C++.What is Programming?\n\nProgramming is the process of creating a set of instructions that tell a computer how to perform a task. Programming can be done using a variety of computer programming languages, such as JavaScript, Python, and C++.What is Programming?\n\nProgramming is the process of creating a set of instructions that tell a computer how to perform a task. Programming can be done using a variety of computer programming languages, such as JavaScript, Python, and C++.What is Programming?\n\nProgramming is the process of creating a set of instructions that tell a computer how to perform a task. Programming can be done using a variety of computer programming languages, such as JavaScript, Python, and C++.What is Programming?\n\nProgramming is the process of creating a set of instructions that tell a computer how to perform a task. Programming can be done using a variety of computer programming languages, such as JavaScript, Python, and C++.What is Programming?\n\nProgramming is the process of creating a set of instructions that tell a computer how to perform a task. Programming can be done using a variety of computer programming languages, such as JavaScript, Python, and C++.What is Programming?\n\nProgramming is the process of creating a set of instructions that tell a computer how to perform a task. Programming can be done using a variety of computer programming languages, such as JavaScript, Python, and C++.What is Programming?\n\nProgramming is the process of creating a set of instructions that tell a computer how to perform a task. Programming can be done using a variety of computer programming languages, such as JavaScript, Python, and C++.What is Programming?\n\nProgramming is the process of creating a set of instructions that tell a computer how to perform a task. Programming can be done using a variety of computer programming languages, such as JavaScript, Python, and C++.What is Programming?\n\nProgramming is the process of creating a set of instructions that tell a computer how to perform a task. Programming can be done using a variety of computer programming languages, such as JavaScript, Python, and C++.What is Programming?\n\nProgramming is the process of creating a set of instructions that tell a computer how to perform a task. Programming can be done using a variety of computer programming languages, such as JavaScript, Python, and C++.What is Programming?\n\nProgramming is the process of creating a set of instructions that tell a computer how to perform a task. Programming can be done using a variety of computer programming languages, such as JavaScript, Python, and C++.What is Programming?\n\nProgramming is the process of creating a set of instructions that tell a computer how to perform a task. Programming can be done using a variety of computer programming languages, such as JavaScript, Python, and C++.What is Programming?\n\nProgramming is the process of creating a set of instructions that tell a computer how to perform a task. Programming can be done using a variety of computer programming languages, such as JavaScript, Python, and C++.What is Programming?\n\nProgramming is the process of creating a set of instructions that tell a computer how to perform a task. Programming can be done using a variety of computer programming languages, such as JavaScript, Python, and C++.What is Programming?\n\nProgramming is the process of creating a set of instructions that tell a computer how to perform a task. Programming can be done using a variety of computer programming languages, such as JavaScript, Python, and C++.What is Programming?\n\nProgramming is the process of creating a set of instructions that tell a computer how to perform a task. Programming can be done using a variety of computer programming languages, such as JavaScript, Python, and C++.What is Programming?\n\nProgramming is the process of creating a set of instructions that tell a computer how to perform a task. Programming can be done using a variety of computer programming languages, such as JavaScript, Python, and C++.What is Programming?\n\nProgramming is the process of creating a set of instructions that tell a computer how to perform a task. Programming can be done using a variety of computer programming languages, such as JavaScript, Python, and C++.",
            "Programming involves tasks such as analysis, generating algorithms, profiling algorithms' accuracy and resource consumption, and the implementation of algorithms in a chosen programming language.",
            "The purpose of programming is to find a sequence of instructions that will automate the performance of a task on a computer, often for solving a given problem."
        ]
    ),
    Ebook(
        id: "ebook_002", 
        name: "Mastering Python", 
        title: "Advanced Python Techniques", 
        instruction: "Master advanced features in Python.",
        author: "Jane Smith",
        coverImage: "default_cover", // 🔧 改為 default_cover
        content: [
            "Chapter 1: Python Decorators\n\nDecorators are a powerful and expressive feature in Python that allow you to modify the behavior of functions and methods.",
            "A decorator is a function that takes another function as an argument and extends its behavior without explicitly modifying it.",
            "This is a great example of the open/closed principle: code should be open for extension but closed for modification."
        ]
    ),
    Ebook(
        id: "ebook_003", 
        name: "Design Patterns", 
        title: "Understanding Software Design Patterns", 
        instruction: "Explore common software design patterns.",
        author: "Robert Martin",
        coverImage: "default_cover", // 🔧 改為 default_cover
        content: [
            "Chapter 1: Introduction to Design Patterns\n\nDesign patterns are typical solutions to common problems in software design. Each pattern is like a blueprint that you can customize to solve a particular design problem in your code.",
            "Patterns are a toolkit of solutions to common problems in software design. They define a common language that helps your team communicate more efficiently.",
            "Design patterns differ by their complexity, level of detail, and scale of applicability to the entire system being designed."
        ]
    ),
    Ebook(
        id: "ebook_004", 
        name: "Data Science with R", 
        title: "Data Science Fundamentals", 
        instruction: "Learn data science using R programming.",
        author: "Emily Chen",
        coverImage: "default_cover", // 🔧 改為 default_cover
        content: [
            "Chapter 1: Introduction to Data Science\n\nData science is an interdisciplinary field that uses scientific methods, processes, algorithms and systems to extract knowledge and insights from structured and unstructured data.",
            "R is a programming language and free software environment for statistical computing and graphics supported by the R Foundation for Statistical Computing.",
            "The R language is widely used among statisticians and data miners for developing statistical software and data analysis."
        ]
    )
]

