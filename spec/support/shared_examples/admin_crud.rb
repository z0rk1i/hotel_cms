RSpec.shared_examples "admin CRUD resource" do
  let(:model_key) { model_class.model_name.param_key }

  describe "GET collection" do
    it "lists existing records" do
      record
      get collection_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(listed_title)
    end
  end

  describe "GET new" do
    it "renders the form" do
      get new_form_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST collection" do
    it "creates a record and redirects to the collection" do
      expect { post collection_path, params: { model_key => valid_attrs } }
        .to change(model_class, :count).by(1)
      assert_assigned(model_class.last, valid_attrs)
      expect(response).to redirect_to(collection_path)
    end

    it "re-renders the form on invalid attributes" do
      post collection_path, params: { model_key => invalid_attrs }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET edit" do
    it "renders the edit form with the current title" do
      get edit_member_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(initial_title)
    end
  end

  describe "PATCH member" do
    it "updates the record and redirects to the collection" do
      patch member_path, params: { model_key => update_attrs }
      assert_assigned(record.reload, update_attrs)
      expect(response).to redirect_to(collection_path)
    end

    it "re-renders the form on invalid attributes" do
      patch member_path, params: { model_key => invalid_attrs }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE member" do
    it "destroys the record and redirects to the collection" do
      record
      expect { delete member_path }.to change(model_class, :count).by(-1)
      expect(response).to redirect_to(collection_path)
    end
  end

  private

  def assert_assigned(record, attrs)
    attrs.each do |attr, value|
      if value.respond_to?(:original_filename)
        expect(record.public_send(attr)).to be_attached
      else
        expect(record.public_send(attr)).to eq(value)
      end
    end
  end
end
