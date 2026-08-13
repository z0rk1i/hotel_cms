module Admin
  class ReportsController < BaseController
    def show
      @from = parse_date(:from) || Date.current.beginning_of_month
      @to = parse_date(:to) || Date.current.end_of_month
      @from, @to = @to, @from if @from > @to
      @report = Report.refresh!(from: @from, to: @to)

      respond_to do |format|
        format.html
        format.csv { send_csv }
      end
    end

    private

    def parse_date(key)
      value = params[key]
      return nil if value.blank?

      Date.parse(value)
    rescue ArgumentError, TypeError
      nil
    end

    def send_csv
      headers = [ "Дата", "По тарифу (план), ₽", "Принято (факт), ₽" ]
      rows = @report.nightly.map do |date, values|
        [ date, values.fetch("plan", 0), values.fetch("fact", 0) ]
      end
      rows.unshift([ "Итого", @report.plan_revenue, @report.fact_revenue ])

      send_data CSV.generate(headers: headers, write_headers: true) { |csv| rows.each { |row| csv << row } },
                filename: "report_#{@from.iso8601}_#{@to.iso8601}.csv",
                type: "text/csv"
    end
  end
end
