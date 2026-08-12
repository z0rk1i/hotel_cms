module Admin
  class ReportsController < BaseController
    def index
      @report = build_report
    end

    def export
      report = build_report
      send_data ReportsCsvExporter.export(report),
                filename: "report_#{report.from.iso8601}_#{report.to.iso8601}.csv",
                type: "text/csv"
    end

    private

    def build_report
      Reports::PeriodReport.new(from: from_date, to: to_date)
    end

    def from_date
      parse_date(:from) || Date.current.beginning_of_month
    end

    def to_date
      parse_date(:to) || [ Date.current.end_of_month, from_date + Reports::PeriodReport::MAX_RANGE_DAYS ].min
    end

    def parse_date(key)
      value = params[key]
      return nil if value.blank?

      Date.parse(value)
    rescue ArgumentError, TypeError
      nil
    end
  end
end
