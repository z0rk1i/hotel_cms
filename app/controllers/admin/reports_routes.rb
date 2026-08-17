require "csv"

module Admin
  module ReportsRoutes
    def self.registered(app)
      app.get "/reports" do
        @from = parse_date(params["from"]) || Date.current.beginning_of_month
        @to = parse_date(params["to"]) || Date.current.end_of_month
        @from, @to = @to, @from if @from > @to
        @report = Report.refresh!(from: @from, to: @to)

        if params["format"] == "csv"
          content_type "text/csv"
          headers "Content-Disposition" => %(attachment; filename="report_#{@from.iso8601}_#{@to.iso8601}.csv")
          body build_report_csv
        else
          haml :"admin/reports/show", layout: :admin
        end
      end

      app.helpers do
        private

        def build_report_csv
          headers = [ "Дата", "По тарифу (план), ₽", "Принято (факт), ₽" ]
          rows = @report.nightly.map do |date, values|
            [ date, values.fetch("plan", 0), values.fetch("fact", 0) ]
          end
          rows.unshift([ "Итого", @report.plan_revenue, @report.fact_revenue ])
          CSV.generate(headers: headers, write_headers: true) { |csv| rows.each { |row| csv << row } }
        end
      end
    end
  end
end
