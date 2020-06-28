//
//  TaskRepository.swift
//  tasks
//
//  Created by Lisandro on 14/06/2020.
//  Copyright © 2020 Lisandro Falconi. All rights reserved.
//

import Foundation
import FirebaseFirestore
import Combine
import Resolver

class BaseTaskRepository {
    @Published var tasks = [Task]()
}

protocol TaskRepository: BaseTaskRepository {
    func addTask(_ task: Task)
    func removeTask(_ task: Task)
    func updateTask(_ task: Task)
}

class TestDataTaskRepository: BaseTaskRepository, TaskRepository, ObservableObject {
    override init() {
        super.init()
        tasks = testDataTasks
    }
    func addTask(_ task: Task) {
        tasks.append(task)
    }
    
    func removeTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks.remove(at: index)
        }
    }
    
    func updateTask(_ task: Task) {
        if let index = self.tasks.firstIndex(where: { $0.id == task.id } ) {
            self.tasks[index] = task
        }
    }
}


class LocalTaskRepository: BaseTaskRepository, TaskRepository, ObservableObject {
    override init() {
        super.init()
        loadData()
    }
    
    func addTask(_ task: Task) {
        self.tasks.append(task)
        saveData()
    }
    
    func removeTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks.remove(at: index)
            saveData()
        }
    }
    
    func updateTask(_ task: Task) {
        if let index = self.tasks.firstIndex(where: { $0.id == task.id } ) {
            self.tasks[index] = task
            saveData()
        }
    }
    
    private func loadData() {
        //    do {
        //        let data = FileManager.default.contents(atPath: "tasks.json")
        //        let retrievedTasks = try JSONDecoder().decode([Task].self, from: data)
        //    } catch {
        //
        //    }
        //    if let retrievedTasks = try? Disk.retrieve("tasks.json", from: .documents, as: [Task].self) { // (1)
        //      self.tasks = retrievedTasks
        //    }
    }
    
    private func saveData() {
        //    do {
        //      try Disk.save(self.tasks, to: .documents, as: "tasks.json") // (2)
        //    }
        //    catch let error as NSError {
        //      fatalError("""
        //        Domain: \(error.domain)
        //        Code: \(error.code)
        //        Description: \(error.localizedDescription)
        //        Failure Reason: \(error.localizedFailureReason ?? "")
        //        Suggestions: \(error.localizedRecoverySuggestion ?? "")
        //        """)
        //    }
    }
}

class FirebaseTaskRepository: BaseTaskRepository, TaskRepository, ObservableObject {
    var db = Firestore.firestore()
    
    @Injected var authenticationService: AuthenticationService // (1)
    
    var tasksPath: String = "tasks" // (2)
    
    var userId: String = "unknown"
    
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        //loadData()
        authenticationService.$user // (3)
            .compactMap { user in
                user?.uid // (4)
        }
            .assign(to: \.userId, on: self) // (5)
            .store(in: &cancellables)
        
        // (re)load data if user changes
        authenticationService.$user // (6)
            .receive(on: DispatchQueue.main) // (7)
            .sink { user in
                self.loadData() // (8)
        }
        .store(in: &cancellables)
    }
    
    private func loadData() {
        db.collection("tasks")
            .whereField("userId", isEqualTo: self.userId) // (9)
            .order(by: "createdTime")
            .addSnapshotListener { (querySnapshot, error) in // (2)
                if let querySnapshot = querySnapshot {
                    self.tasks = querySnapshot.documents.compactMap { document -> Task? in // (3)
                        try? document.data(as: Task.self) // (4)
                    }
                }
        }
    }
    
    func addTask(_ task: Task) {
        /*
         Firestore will call the snapshot listener we’ve registered on the tasks collection
         immediately after making any changes to the contained documents - even if the application is currently offline.
         */
        do {
            var userTask = task
            userTask.userId = self.userId // (10)
            let _ = try db.collection("tasks").addDocument(from: userTask)
        }
        catch {
            print("⚠️ There was an error while trying to save a task \(error.localizedDescription).")
        }
    }
    
    func removeTask(_ task: Task) {
        if let taskID = task.id {
            db.collection("tasks").document(taskID).delete { (error) in // (1)
                if let error = error {
                    print("Error removing document: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func updateTask(_ task: Task) {
        if let taskID = task.id {
            do {
                try db.collection("tasks").document(taskID).setData(from: task) // (1)
            }
            catch {
                print("There was an error while trying to update a task \(error.localizedDescription).")
            }
        }
    }
}
