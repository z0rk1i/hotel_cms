require "csv"

class GuestsCsvExporter
  HEADERS = [ "Имя", "Телефон", "Email", "Паспорт", "Заметки", "Создан", "VIP", "Предпочтения" ].freeze

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
          guest.created_at.to_date.iso8601,
          guest.is_vip ? "да" : "",
          guest.preferences
        ]
      end
    end
  end
end
