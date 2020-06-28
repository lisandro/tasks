//
//  ContentView.swift
//  tasks
//
//  Created by Lisandro on 07/06/2020.
//  Copyright © 2020 Lisandro Falconi. All rights reserved.
//

import SwiftUI
import Combine

struct ContentView: View {
    @ObservedObject var taskListVM = TaskListViewModel() // (7)
    @State var presentAddNewItem = false
    
    var body: some View {
        NavigationView { // (2)
            VStack(alignment: .leading) {
                List {
                    ForEach (taskListVM.taskCellViewModels) { taskCellVM in // (3)
                        TaskCell(taskCellVM: taskCellVM) // (6)
                    }
                        .onDelete { indexSet in // (4)
                            self.taskListVM.removeTasks(atOffsets: indexSet)
                            
                    }
                    if presentAddNewItem { // (5)
                        TaskCell(taskCellVM: TaskCellViewModel.newTask()) { result in // (2)
                            if case .success(let task) = result {
                                self.taskListVM.addTask(task: task) // (3)
                            }
                            self.presentAddNewItem.toggle() // (4)
                        }
                    }
                }
                
                Button(action: { self.presentAddNewItem.toggle() }) { // (7)
                    HStack {
                        Image(systemName: "plus.circle.fill") //(8)
                            .resizable()
                            .frame(width: 20, height: 20) // (11)
                        Text("New Task") // (9)
                    }
                }
                .padding()
                    .accentColor(Color(UIColor.systemRed)) // (13)
            }
            .navigationBarTitle("Tasks")
        }
    }
    
}

struct TaskCell: View { // (5)
    @ObservedObject var taskCellVM: TaskCellViewModel
    var onCommit: (Result<Task, InputError>) -> Void = { _ in } // (5)
    
    var body: some View {
        HStack {
            Image(systemName: taskCellVM.completionStateIconName)
                .resizable()
                .frame(width: 20, height: 20)
                .onTapGesture {
                    self.taskCellVM.task.completed.toggle()
            }
            TextField("Enter task title", text: $taskCellVM.task.title, // (3)
                onCommit: { //(4)
                    if !self.taskCellVM.task.title.isEmpty {
                        self.onCommit(.success(self.taskCellVM.task))
                    }
                    else {
                        self.onCommit(.failure(.empty))
                    }
            }).id(taskCellVM.id)
        }
    }
}
enum InputError: Error {
    case empty
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
