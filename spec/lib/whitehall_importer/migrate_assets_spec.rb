# frozen_string_literal: true

RSpec.describe WhitehallImporter::MigrateAssets do
  describe ".call" do
    # These proved a bit confusing as we frequently create an asset variable as well
    # I think we can live without them
    # let(:asset_id) { "847150" }
    # let(:original_asset_url) { "https://asset-manager.gov.uk/blah/#{asset_id}/asset" }
    # let(:asset) { build(:whitehall_migration_asset_import) }

    # can simplify the before :each to a one liner
    before { stub_any_asset_manager_call }

    # I don't think you need this this test since it's asserted implicitly in other tests
    it "should take a WhitehallMigration::DocumentImport record as an argument" do
      expect { described_class.call(build(:whitehall_migration_document_import)) }.not_to raise_error
    end

    it "should skip migrating any assets that have already been processed" do
      asset = build(:whitehall_migration_asset_import, state: "removed")
      whitehall_import = build(:whitehall_migration_document_import, assets: [asset])
      expect(asset).not_to receive(:update!)
      asset_manager_call = stub_any_asset_manager_call
      described_class.call(whitehall_import)
      expect(asset_manager_call).to_not have_been_requested
    end

    it "should log individual errors and put asset into a migration failed state" do
      asset = build(:whitehall_migration_asset_import)
      whitehall_import = build(:whitehall_migration_document_import, assets: [asset])
      allow(asset).to receive(:whitehall_asset_id).and_raise("Some error")
      expect { described_class.call(whitehall_import) }
        .to raise_error "Failed migrating at least one Whitehall asset"
      expect(asset.state).to eq("migration_failed")
      expect(asset.error_message).to include("Some error")
    end

    it "should attempt to migrate all assets and raise error only at the end" do
      asset = build(:whitehall_migration_asset_import)
      bad_asset = build(:whitehall_migration_asset_import)
      allow(bad_asset).to receive(:whitehall_asset_id).and_raise
      whitehall_import = build(:whitehall_migration_document_import, assets: [bad_asset, asset])

      expect { described_class.call(whitehall_import) }
        .to raise_error "Failed migrating at least one Whitehall asset"
      expect(bad_asset.state).to eq("migration_failed")
      expect(asset.state).not_to eq("migration_failed")
    end

    it "should delete draft assets" do
      image_revision = build(:image_revision, :on_asset_manager, state: :draft)
      asset = create(:whitehall_migration_asset_import, image_revision: image_revision)
      whitehall_import = build(:whitehall_migration_document_import, assets: [asset])
      delete_asset_request = stub_asset_manager_delete_asset(asset.whitehall_asset_id)

      described_class.call(whitehall_import)
      expect(delete_asset_request).to have_been_requested
      expect(asset.state).to eq("removed")
    end

    it "should delete draft asset variants" do
      image_revision = build(:image_revision, :on_asset_manager, state: :draft)
      asset = create(:whitehall_migration_asset_import,
                     image_revision: image_revision,
                     variant: "s300")
      delete_asset_request = stub_asset_manager_delete_asset(asset.whitehall_asset_id)
      whitehall_import = build(:whitehall_migration_document_import, assets: [asset])

      described_class.call(whitehall_import)
      expect(delete_asset_request).to have_been_requested
      expect(asset.state).to eq("removed")
    end

    it "should redirect live attachments to their content publisher equivalents" do
      asset = build(:whitehall_migration_asset_import, :for_file_attachment)
      whitehall_import = build(:whitehall_migration_document_import, assets: [asset])
      redirect_request = stub_asset_manager_update_asset(
        asset.whitehall_asset_id,
        redirect_url: asset.file_attachment_revision.asset_url,
      )

      described_class.call(whitehall_import)
      expect(redirect_request).to have_been_requested
      expect(asset.state).to eq("redirected")
    end

    it "should delete attachment variants even if they are live" do
      asset = create(:whitehall_migration_asset_import,
                     :for_file_attachment,
                     variant: "thumbnail")
      whitehall_import = build(:whitehall_migration_document_import, assets: [asset])
      delete_request = stub_asset_manager_delete_asset(asset.whitehall_asset_id)

      described_class.call(whitehall_import)
      expect(delete_request).to have_been_requested
      expect(asset.state).to eq("removed")
    end

    it "should redirect live images to their content publisher equivalents" do
      asset = build(:whitehall_migration_asset_import, :for_image)
      whitehall_import = build(:whitehall_migration_document_import, assets: [asset])
      redirect_request = stub_asset_manager_update_asset(
        asset.whitehall_asset_id,
        redirect_url: asset.image_revision.asset_url("960"),
      )

      described_class.call(whitehall_import)
      expect(redirect_request).to have_been_requested
      expect(asset.state).to eq("redirected")
    end

    it "should redirect live image variants to their content publisher equivalents" do
      asset = build(:whitehall_migration_asset_import, :for_image, variant: "s300")
      whitehall_import = build(:whitehall_migration_document_import, assets: [asset])
      redirect_request = stub_asset_manager_update_asset(
        asset.whitehall_asset_id,
        redirect_url: asset.image_revision.asset_url("300"),
      )

      described_class.call(whitehall_import)
      expect(redirect_request).to have_been_requested
      expect(asset.state).to eq("redirected")
    end

    it "should delete live image variants that have no content publisher equivalent" do
      asset = build(:whitehall_migration_asset_import, :for_image, variant: "s216")
      whitehall_import = build(:whitehall_migration_document_import, assets: [asset])
      delete_request = stub_asset_manager_delete_asset(asset.whitehall_asset_id)

      described_class.call(whitehall_import)
      expect(delete_request).to have_been_requested
      expect(asset.state).to eq("removed")
    end
  end
end
