require "csv"

class GuestsCsvExporter
  HEADERS = [ "Имя", "Телефон", "Email", "Паспорт", "Заметки", "Создан" ].freeze

  def self.export(scope)
    CSV.generate(headers: true) do |csv|
      csv << HEADERS
      scope.each do |guest|
        csv << [
          guest.full_name,
          guest.phone,
          guest.email,
          guest.passport_number,
          guest.notes,
          guest.created_at.to_date.iso8601
        ]
      end
    end
  end
end
