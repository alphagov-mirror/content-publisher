RSpec.describe "Whitehall Migration" do
  let(:whitehall_migration) { create(:whitehall_migration) }

  before do
    login_as(create(:user))
  end

  describe "GET /whitehall-migration/:migration_id" do
    it "returns success" do
      get whitehall_migration_path(whitehall_migration)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /whitehall-migration/:migration_id/documents" do
    it "returns success" do
      create(:whitehall_migration_document_import, whitehall_migration_id: whitehall_migration.id)
      get whitehall_migration_documents_path(whitehall_migration.id)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /whitehall-migration/:migration_id/documents/:document_import_id" do
    it "returns success" do
      document_import = create(:whitehall_migration_document_import, whitehall_migration_id: whitehall_migration.id)
      get whitehall_migration_document_path(whitehall_migration.id, document_import.id)

      expect(response).to have_http_status(:ok)
    end
  end
end
