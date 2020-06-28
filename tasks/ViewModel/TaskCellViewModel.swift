//
//  TaskCellViewModel.swift
//  tasks
//
//  Created by Lisandro on 07/06/2020.
//  Copyright © 2020 Lisandro Falconi. All rights reserved.
//

import Foundation
import Combine
import Resolver

class TaskCellViewModel: ObservableObject, Identifiable {
    @Injected var taskRepository: TaskRepository
    var id = ""
    @Published var task: Task
    @Published var completionStateIconName = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    init(task: Task) {
        self.task = task
        $task
          .map { $0.completed ? "checkmark.circle.fill" : "circle" }
          .assign(to: \.completionStateIconName, on: self)
          .store(in: &cancellables)

        $task
          .compactMap { $0.id }
          .assign(to: \.id, on: self)
          .store(in: &cancellables)
        
        $task
          .dropFirst()
          .debounce(for: 0.8, scheduler: RunLoop.main)
          .sink { task in
            self.taskRepository.updateTask(task)
          }
          .store(in: &cancellables)
    }
    
    static func newTask() -> TaskCellViewModel {
        TaskCellViewModel(task: Task(title: "", priority: .medium, completed: false))
    }
}
