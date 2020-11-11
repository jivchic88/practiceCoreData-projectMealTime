//
//  ViewController.swift
//  MealTime
//
//  Created by Ivan Akulov on 10/11/16.
//  Copyright © 2016 Ivan Akulov. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController, UITableViewDataSource {
    
    var context: NSManagedObjectContext!
    @IBOutlet weak var tableView: UITableView!
    var array = [Date]()
    
    // создаем экземпляр класса person - все приемы пищи будут привязываться к этому экземпляру класса person
    var person: Person!
    
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        // проверка наличия значений нашего экземпляра person в Core Data (в контексте)
        // если их нет - создаем конкретный экземпляр person и уже помещать новые значения в Core Data
        let personName = "Max"
        
        // создали запрос
        let fetchRequest: NSFetchRequest<Person> = Person.fetchRequest()
        
        // создали условие для поиска в Core Data - запись Person с именем "Max"
        fetchRequest.predicate = NSPredicate(format: "name = %@", personName)
        
        // пытаемся выполнить запрос на поиск в Core Data
        do {
            let results = try context.fetch(fetchRequest)
            
            // если человек по имени не найден = записать значение в контекст
            if results.isEmpty {
                // сознаем новый экземпляр класса Person, который помещаем в наш контекст
                // это возможно (короткая инициализация) - так как мы создали class Person от NSManagedObject (поэтому не нужно указывать отдельно entity)
                person = Person(context: context)
                
                // присваиваем экземпляру в свойство name - прилетевшее имя
                person.name = personName
                
                // пытаемся сохранить наш контекст
                try context.save()
                
            } else {
                // если рerson с конкретным именем уже есть в базе - то присваиваем значения
                person = results.first
            }
            // catch let error as NSError - такая запись так как у нас будет доступ к конкретноу описанию ошибки
        } catch let error as NSError{
            // error.userInfo - получим описание ошибки, которое заранее помещено в словарь
            print(error.userInfo)
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "My happy meal time"
    }
    
    // numberOfRowsInSection - метод определяет сколько ячеек таблицы нужно для отображения информации
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // проверяем если meais равен nil, то возвращаем 1 ряд - чтобы приложение не упало при отсутствии значенений
        guard let meals = person.meals else { return 1 }
        
        // если meais не равен nil - возвращаем количество приемов пищи
        return  meals.count
    }
    
    //cellForRowAt indexPath - определяет, что должно отображаться в каждой ячейке
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        
        // берем конкретный прием пищи и помещаем его в meal (если он существует)
        // также мы извлекаем дату из meal.date (если онa существует)
        guard let meal = person.meals?[indexPath.row] as? Meal, let mealDate = meal.date else
        {
            // если чего-то нет, то возращаем пустую ячейку
            return cell!
        }
        
        //  если не nil - то отображаем дату приема пищи в ячейке
        cell!.textLabel!.text = dateFormatter.string(from: mealDate)
        return cell!
    }
    
    // кнопка для добавления новой записи
    @IBAction func addButtonPressed(_ sender: AnyObject) {
        
        // создали новый экземпляр класса Meal
        let meal = Meal(context: context)
        
        // присваиваем текущую дату и время свойству экземпляра класса Meal (meal.date) - так как у нас будет содержаться несколько экземпляров Meal в одном Person
        meal.date = Date()
        
        // по умолчанию свойство meals: NSOrderedSet? в классе Person (это set с уже имеющимися значениями и мы не можем изменять этот set - поэтому для изменений сделали mutableCopy() - теперь у нас let meals: NSMutableOrderedSet? - изменяемая последовательность)
        // проще - сделали копию и првели к типу NSMutableOrderedSet
        let meals = person.meals?.mutableCopy() as? NSMutableOrderedSet
        
        // добавляем конкретный прием пищи в наш изменяемый meals
        meals?.add(meal)
        
        // переопределяем set созданный как свойство в классе новым изменяемым (созданным здесь)
        person.meals = meals
        
        // сохраняем контекст
        do {
            try context.save()
        } catch let error as NSError {
            print("Error: \(error), userInfo \(error.userInfo)")
        }
        
        // перезагрузка нашей таблицы - для отображения новых значений
        tableView.reloadData()
    }
    
    // ----- MARK - ниже методы для удаления данных из таблицы и базы данных -----
    
    // canEditRowAt - метод определяет данная таблица является редактируемой или нет.
     func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    //editingStyle: UITableViewCell.EditingStyle - Определяем стиль редактирования ячейки.
    // предоставляет исполнение соответствующего кода для каждого действия
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        // сначала нужно получить тот объект, который нужно удалить
        guard let mealToDelete = person.meals?[indexPath.row] as? Meal, editingStyle == .delete else { return }
        
        // если объект создан и стиль - удаление, то удаляем контекст из базы
        context.delete(mealToDelete)
        
        // после удаления - нужно пересохранить наш контекст
        do {
            
            try context.save()
            
            // после того, как нам удалось удалить объект из базы данных - мы можем его удалить из таблицы!!!
            // удаляем по индексу с автоматической анимашкой
            tableView.deleteRows(at: [indexPath], with: .automatic)
            
        } catch let error as NSError {
            print("Error: \(error), description: \(error.userInfo)")
        }
    }
}

