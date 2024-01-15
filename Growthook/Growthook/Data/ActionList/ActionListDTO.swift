//
//  ActionListDTO.swift
//  Growthook
//
//  Created by 천성우 on 1/11/24.
//

import Foundation


struct ActionListPercentResponse: Codable {
    let data: Int
}

struct ActionListDoingResponse: Codable {
    let actionPlanId: Int
    let content: String
    let isScraped: Bool
    let seedId: Int
}

struct ActionListFinishedResponse: Codable {
    let actionPlanId: Int
    let content: String
    let isScraped: Bool
    let seedId: Int
}

struct ActionListCompletionResponse: Codable {
    
}

struct ActionListReviewDetailResponse: Codable {
    let actionPlan: String
    let isScraped: Bool
    let content, reviewDate: String
}

struct ActionListReviewPostRequest: Codable {
    let content: String
}

struct ActionListReviewPostResponse: Codable {
    
}
