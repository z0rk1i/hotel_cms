require "csv"

class BookingsCsvExporter
  HEADERS = [ "id", "Гость", "Телефон", "Email", "Номер", "Заезд", "Выезд", "Ночей", "Гостей", "Сумма, ₽", "Оплачено, ₽", "Долг, ₽", "Статус", "Создана" ].freeze

  def self.export(scope)
    CSV.generate(headers: true) do |csv|
      csv << HEADERS
      scope.includes(:guest, :room, :payments).each do |booking|
        paid = booking.payments.sum(&:amount)
        csv << [
          booking.id,
          booking.guest.full_name,
          booking.guest.phone,
          booking.guest.email,
          booking.room.number,
          booking.check_in.iso8601,
          booking.check_out.iso8601,
          booking.nights,
          booking.guests_count,
          booking.total_price.to_f,
          paid.to_f,
          (booking.total_price - paid).to_f,
          Booking.status_labels.fetch(booking.status, booking.status),
          booking.created_at.to_date.iso8601
        ]
      end
    end
  end
end
