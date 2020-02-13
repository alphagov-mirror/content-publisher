RSpec.describe "Whitehall Migration" do
  let(:whitehall_migration) { create(:whitehall_migration) }
  let(:user) { create(:user, permissions: [User::DEBUG_PERMISSION]) }

  before do
    login_as(user)
  end

  describe "GET /whitehall-migration/:migration_id" do
    it "returns success" do
      get whitehall_migration_path(whitehall_migration)

      expect(response).to have_http_status(:ok)
    end

    it "returns a forbidden status for user without debug permission" do
       login_as(create(:user))
       get whitehall_migration_path(whitehall_migration)

       expect(response).to have_http_status(:forbidden)
       expect(response.body).to have_content("Sorry, you don't seem to have the #{User::DEBUG_PERMISSION} permission for this app")
    end
  end

  describe "GET /whitehall-migration/:migration_id/documents" do
    it "returns success" do
      create(:whitehall_migration_document_import, whitehall_migration_id: whitehall_migration.id)
      get whitehall_migration_documents_path(whitehall_migration.id)

      expect(response).to have_http_status(:ok)
    end

    it "returns a forbidden status for user without debug permission" do
       login_as(create(:user))

       create(:whitehall_migration_document_import, whitehall_migration_id: whitehall_migration.id)
       get whitehall_migration_documents_path(whitehall_migration.id)

       expect(response).to have_http_status(:forbidden)
       expect(response.body).to have_content("Sorry, you don't seem to have the #{User::DEBUG_PERMISSION} permission for this app")
    end
  end

  describe "GET /whitehall-migration/:migration_id/documents/:document_import_id" do
    it "returns success" do
      document_import = create(:whitehall_migration_document_import, whitehall_migration_id: whitehall_migration.id)
      get whitehall_migration_document_path(whitehall_migration.id, document_import.id)

      expect(response).to have_http_status(:ok)
    end

    it "returns a forbidden status for user without debug permission" do
       login_as(create(:user))
       document_import = create(:whitehall_migration_document_import, whitehall_migration_id: whitehall_migration.id)
       get whitehall_migration_document_path(whitehall_migration.id, document_import.id)

       expect(response).to have_http_status(:forbidden)
       expect(response.body).to have_content("Sorry, you don't seem to have the #{User::DEBUG_PERMISSION} permission for this app")
    end
  end
end
