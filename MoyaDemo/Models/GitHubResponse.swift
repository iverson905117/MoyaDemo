//
//  GitHubResponse.swift
//  MoyaDemo
//
//  Created by i_vickang on 2020/9/24.
//  Copyright © 2020 i_vickang. All rights reserved.
//

import Foundation

struct User: Codable {
    var avatarUrl: String?
    var bio: String?
    var blog: String?
    var company: String?
    var createdAt: String?
    var email: String?
    var eventsUrl: String?
    var followers: String?
    var followersUrl: String?
    var following: String?
    var followingUrl: String?
    var gistsUrl: String?
    var gravatarId: String?
    var hireable: String?
    var htmlUrl: String?
    var id: Int?
    var location: String?
    var login: String?
    var name: String?
    var nodeId: String?
    var organizationsUrl: String?
    var publicGists: Int?
    var publicRepos: Int?
    var receivedEventsUrl: String?
    var reposUrl: String?
    var siteAdmin: Bool?
    var starredUrl: String?
    var subscriptionsUrl: String?
    var twitterUsername: String?
    var type: String?
    var updatedAt: String?
    var url: String?
}
