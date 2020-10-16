//
//  GitHubResponse.swift
//  MoyaDemo
//
//  Created by i_vickang on 2020/9/24.
//  Copyright © 2020 i_vickang. All rights reserved.
//

import Foundation

struct UserResponse: BaseResponse {
    var code: Int = 200
    var avatarUrl: String?
    var bio: String?
    var blog: String?
    var company: String?
    var createdAt: String?
    var email: String?
    var eventsUrl: String?
    var followersUrl: String?
    var followingUrl: String?
    var gistsUrl: String?
    var gravatarId: String?
    var hireable: Bool?
    var htmlUrl: String?
    var location: String?
    var login: String?
    var name: String?
    var nodeId: String?
    var organizationsUrl: String?
    var receivedEventsUrl: String?
    var reposUrl: String?
    var siteAdmin: Bool?
    var starredUrl: String?
    var subscriptionsUrl: String?
    var twitterUsername: String?
    var type: String?
    var updatedAt: String?
    var url: String?
    var id: Int?
    var followers: Int?
    var following: Int?
    var publicGists: Int?
    var publicRepos: Int?
    
    private enum CodingKeys: String, CodingKey {
        case avatarUrl = "avatar_url"
        case bio = "bio"
        case blog = "blog"
        case company = "company"
        case createdAt = "created_at"
        case email = "email"
        case eventsUrl = "events_url"
        case followers = "followers"
        case followersUrl = "followers_url"
        case following = "following"
        case followingUrl = "following_url"
        case gistsUrl = "gists_url"
        case gravatarId = "gravatar_id"
        case hireable = "hireable"
        case htmlUrl = "html_url"
        case id = "id"
        case location = "location"
        case login = "login"
        case name = "name"
        case nodeId = "node_id"
        case organizationsUrl = "organizations_url"
        case publicGists = "public_gists"
        case publicRepos = "public_repos"
        case receivedEventsUrl = "received_events_url"
        case reposUrl = "repos_url"
        case siteAdmin = "site_admin"
        case starredUrl = "starred_url"
        case subscriptionsUrl = "subscriptions_url"
        case twitterUsername = "twitter_username"
        case type = "type"
        case updatedAt = "updated_at"
        case url = "url"
    }
}
