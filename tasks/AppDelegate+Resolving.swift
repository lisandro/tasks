//
//  AppDelegate+Resolving.swift
//  tasks
//
//  Created by Lisandro on 14/06/2020.
//  Copyright © 2020 Lisandro Falconi. All rights reserved.
//

import Resolver

extension Resolver: ResolverRegistering {
    public static func registerAllServices() {
        //register { TestDataTaskRepository() as TaskRepository }.scope(application)
        //register { LocalTaskRepository() as TaskRepository }.scope(application)
        register { FirebaseTaskRepository() as TaskRepository }.scope(application)
        register { AuthenticationService() }.scope(application)
    }
}
