require "csv"

class ReportsCsvExporter
  HEADERS = [ "Дата", "План, ₽", "Факт, ₽", "Занято номеров", "Всего номеров", "Загрузка, %" ].freeze

  def self.export(report)
    CSV.generate(headers: true) do |csv|
      csv << HEADERS
      report.night_rows.each do |row|
        csv << [ row[:date].iso8601, row[:plan], row[:fact], row[:sold], row[:total], row[:occupancy] ]
      end
    end
  end
end
