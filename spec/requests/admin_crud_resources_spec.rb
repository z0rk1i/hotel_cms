require "rails_helper"

RSpec.describe "Admin CRUD resources via CrudController", type: :request do
  before { sign_in create(:administrator) }

  it_behaves_like "admin CRUD resource" do
    let(:model_class) { Service }
    let(:collection_path) { admin_services_path }
    let(:new_form_path) { new_admin_service_path }
    let(:initial_title) { "Завтрак" }
    let(:record) { create(:service, name: initial_title) }
    let(:edit_member_path) { edit_admin_service_path(record) }
    let(:member_path) { admin_service_path(record) }
    let(:listed_title) { initial_title }
    let(:valid_attrs) { { name: "Трансфер", price: 1500 } }
    let(:invalid_attrs) { { name: "" } }
    let(:update_attrs) { { name: "Новое название" } }
  end

  it_behaves_like "admin CRUD resource" do
    let(:model_class) { News }
    let(:collection_path) { admin_news_index_path }
    let(:new_form_path) { new_admin_news_path }
    let(:initial_title) { "Новость о спа" }
    let(:record) { create(:news, title: initial_title) }
    let(:edit_member_path) { edit_admin_news_path(record) }
    let(:member_path) { admin_news_path(record) }
    let(:listed_title) { initial_title }
    let(:valid_attrs) { { title: "Новость", body: "Текст новости", published_at: Time.zone.local(2026, 8, 12, 12, 0, 0) } }
    let(:invalid_attrs) { { title: "" } }
    let(:update_attrs) { { title: "Обновлённая новость" } }
  end

  it_behaves_like "admin CRUD resource" do
    let(:model_class) { Page }
    let(:collection_path) { admin_pages_path }
    let(:new_form_path) { new_admin_page_path }
    let(:initial_title) { "О гостинице" }
    let(:record) { create(:page, title: initial_title) }
    let(:edit_member_path) { edit_admin_page_path(record) }
    let(:member_path) { admin_page_path(record) }
    let(:listed_title) { initial_title }
    let(:valid_attrs) { { slug: "test-page", title: "Страница", body: "Текст" } }
    let(:invalid_attrs) { { title: "" } }
    let(:update_attrs) { { title: "Новый заголовок" } }
  end

  it_behaves_like "admin CRUD resource" do
    let(:model_class) { RoomCategory }
    let(:collection_path) { admin_room_categories_path }
    let(:new_form_path) { new_admin_room_category_path }
    let(:initial_title) { "Стандарт" }
    let(:record) { create(:room_category, name: initial_title) }
    let(:edit_member_path) { edit_admin_room_category_path(record) }
    let(:member_path) { admin_room_category_path(record) }
    let(:listed_title) { initial_title }
    let(:valid_attrs) { { name: "Новый класс", base_price: 4000 } }
    let(:invalid_attrs) { { name: "" } }
    let(:update_attrs) { { name: "Обновлённый класс" } }
  end
end
