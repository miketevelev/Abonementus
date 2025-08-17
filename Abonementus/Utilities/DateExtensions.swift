import Foundation

extension Date {
    // Форматирование даты в строку
    func toString(format: String = "dd.MM.yyyy HH:mm") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: self)
    }
    
    // Проверка, является ли дата сегодняшним днем
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    // Проверка, является ли дата вчерашним днем
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
    
    // Получение начала дня
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    // Получение конца дня
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }
    
    // Получение начала месяца
    var startOfMonth: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: startOfDay)
        return Calendar.current.date(from: components) ?? self
    }
    
    // Получение конца месяца
    var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfMonth) ?? self
    }
    
    // Проверка, истекла ли дата (по сравнению с текущей датой)
    var isExpired: Bool {
        self < Date()
    }
    
    // Добавление дней к дате
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
    
    // Добавление месяцев к дате
    func adding(months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }
    
    // Разница между датами в днях
    func daysBetween(date: Date) -> Int {
        let components = Calendar.current.dateComponents([.day], from: self, to: date)
        return components.day ?? 0
    }
    
    // Проверка, находится ли дата в текущем месяце
    var isInCurrentMonth: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }
    
    // Получение названия месяца
    func monthName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: self).capitalized
    }
    
    // Создание даты из компонентов
    static func from(day: Int, month: Int, year: Int) -> Date? {
        var components = DateComponents()
        components.day = day
        components.month = month
        components.year = year
        return Calendar.current.date(from: components)
    }
    
    // Получение возраста от текущей даты
    func age() -> Int {
        Calendar.current.dateComponents([.year], from: self, to: Date()).year ?? 0
    }
    
    // Проверка, находится ли дата в указанном диапазоне
    func isBetween(_ date1: Date, and date2: Date) -> Bool {
        (min(date1, date2) ... max(date1, date2)).contains(self)
    }
    
    // Получение дня недели
    func dayOfWeek() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: self).capitalized
    }
    
    // Получение короткого названия дня недели
    func shortDayOfWeek() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: self).capitalized
    }
}

// Расширение для Optional<Date>
extension Optional where Wrapped == Date {
    func toString(format: String = "dd.MM.yyyy HH:mm", defaultString: String = "-") -> String {
        guard let date = self else { return defaultString }
        return date.toString(format: format)
    }
    
    var isExpired: Bool {
        guard let date = self else { return false }
        return date.isExpired
    }
}
