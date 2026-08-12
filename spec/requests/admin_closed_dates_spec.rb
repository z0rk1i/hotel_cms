require "rails_helper"

RSpec.describe "Admin closed dates", type: :request do
  before { sign_in create(:administrator) }

  it_behaves_like "admin CRUD resource" do
    let(:model_class) { ClosedDate }
    let(:collection_path) { admin_closed_dates_path }
    let(:new_form_path) { new_admin_closed_date_path }
    let(:tracked_date) { Date.current + 5 }
    let(:initial_title) { tracked_date.to_s }
    let(:record) { create(:closed_date, date: tracked_date) }
    let(:edit_member_path) { edit_admin_closed_date_path(record) }
    let(:member_path) { admin_closed_date_path(record) }
    let(:listed_title) { I18n.l(tracked_date, format: :long) }
    let(:valid_attrs) { { date: Date.current + 9, reason: "Ремонт" } }
    let(:invalid_attrs) { { date: "" } }
    let(:update_attrs) { { date: Date.current + 11 } }
  end
end
