# frozen_string_literal: true

RSpec.describe WhitehallImporter::MigrateAssets do
  describe ".call" do
    let(:asset_id) { "847150" }
    let(:original_asset_url) { "https://asset-manager.gov.uk/blah/#{asset_id}/asset" }
    let(:asset) { build(:whitehall_migration_asset_import) }

    before :each do
      stub_any_asset_manager_call
    end

    it "should take a WhitehallMigration::DocumentImport record as an argument" do
      expect { described_class.call(build(:whitehall_migration_document_import)) }.not_to raise_error
    end

    it "should skip migrating any assets that have already been processed" do
      asset = create(:whitehall_migration_asset_import, state: "removed")
      whitehall_import = build(:whitehall_migration_document_import, assets: [asset])
      expect(asset).not_to receive(:update!)
      asset_manager_call = stub_any_asset_manager_call
      described_class.call(whitehall_import)
      expect(asset_manager_call).to_not have_been_requested
    end

    it "should log individual errors and put asset into an aborted state" do
      whitehall_import = build(:whitehall_migration_document_import, assets: [asset])
      allow(asset).to receive(:whitehall_asset_id).and_raise(StandardError.new("Some error"))
      expect { described_class.call(whitehall_import) }.to raise_error "Failed migrating at least one Whitehall asset"
      expect(asset.state).to eq("migration_failed")
      expect(asset.error_message).to include("Some error")
    end

    it "should attempt to migrate all assets and raise error only at the end" do
      bad_asset = build(:whitehall_migration_asset_import)
      allow(bad_asset).to receive(:whitehall_asset_id).and_raise(StandardError.new)
      whitehall_import = build(:whitehall_migration_document_import, assets: [bad_asset, asset])

      expect { described_class.call(whitehall_import) }
        .to raise_error "Failed migrating at least one Whitehall asset"
      expect(bad_asset.state).to eq("migration_failed")
      expect(asset.state).to eq("removed") # draft asset removed - success
    end

    it "should delete draft assets" do
      asset = create(:whitehall_migration_asset_import)
      delete_asset_request = stub_asset_manager_delete_asset(asset_id)
      whitehall_import = build(:whitehall_migration_document_import, assets: [asset])

      described_class.call(whitehall_import)
      expect(delete_asset_request).to have_been_requested
      expect(asset.state).to eq("removed")
    end

    it "should delete draft asset variants" do
      asset = create(:whitehall_migration_asset_import, :for_image, variant: "s300")
      delete_asset_request = stub_asset_manager_delete_asset(asset_id)
      whitehall_import = build(:whitehall_migration_document_import, assets: [asset])

      described_class.call(whitehall_import)
      expect(delete_asset_request).to have_been_requested
      expect(asset.state).to eq("removed")
    end

    it "should redirect live attachments to their content publisher equivalents" do
      new_file_url = "https://asset-manager.gov.uk/NEW/847151/foo.pdf"
      file_attachment_asset = create(:file_attachment_asset,
                                     state: "live",
                                     file_url: new_file_url)
      asset = build(:whitehall_migration_asset_import,
                    :for_file_attachment,
                    file_attachment_revision: build(:file_attachment_revision,
                                                    blob_revision: file_attachment_asset.blob_revision),
                    original_asset_url: original_asset_url)
      whitehall_import = build(:whitehall_migration_document_import, assets: [asset])
      redirect_request = stub_asset_manager_update_asset(asset_id, redirect_url: new_file_url)

      described_class.call(whitehall_import)
      expect(redirect_request).to have_been_requested
      expect(asset.state).to eq("redirected")
    end

    it "should delete attachment variants even if they are live" do
      file_attachment_asset = build(:file_attachment_asset, state: "live")
      asset = create(:whitehall_migration_asset_import,
                     :for_file_attachment,
                     variant: "thumbnail",
                     file_attachment_revision: build(:file_attachment_revision,
                                                     blob_revision: file_attachment_asset.blob_revision),
                     original_asset_url: original_asset_url)
      whitehall_import = build(:whitehall_migration_document_import, assets: [asset])
      delete_request = stub_asset_manager_delete_asset(asset_id)

      described_class.call(whitehall_import)
      expect(delete_request).to have_been_requested
      expect(asset.state).to eq("removed")
    end

    it "should redirect live images to their content publisher equivalents" do
      new_file_url = "https://asset-manager.gov.uk/NEW/847151/foo.jpg"
      image_asset = create(:image_asset,
                           state: "live",
                           file_url: new_file_url)
      asset = build(:whitehall_migration_asset_import,
                    :for_image,
                    image_revision: build(:image_revision,
                                          blob_revision: image_asset.blob_revision),
                    original_asset_url: original_asset_url)
      whitehall_import = build(:whitehall_migration_document_import, assets: [asset])
      redirect_request = stub_asset_manager_update_asset(asset_id, redirect_url: new_file_url)

      described_class.call(whitehall_import)
      expect(redirect_request).to have_been_requested
      expect(asset.state).to eq("redirected")
    end

    it "should redirect live image variants to their content publisher equivalents" do
      new_file_url = "https://asset-manager.gov.uk/NEW/847152/foo.jpg"
      image_asset = create(:image_asset,
                           variant: "300",
                           state: "live",
                           file_url: new_file_url)
      asset = build(:whitehall_migration_asset_import,
                    :for_image,
                    variant: "s300",
                    image_revision: build(:image_revision, blob_revision: image_asset.blob_revision),
                    original_asset_url: original_asset_url)
      whitehall_import = build(:whitehall_migration_document_import, assets: [asset])
      redirect_request = stub_asset_manager_update_asset(asset_id, redirect_url: new_file_url)

      described_class.call(whitehall_import)
      expect(redirect_request).to have_been_requested
      expect(asset.state).to eq("redirected")
    end

    it "should delete live image variants that have no content publisher equivalent" do
      image_asset = create(:image_asset, state: "live")
      asset = build(:whitehall_migration_asset_import,
                    :for_image,
                    variant: "s216",
                    image_revision: build(:image_revision, blob_revision: image_asset.blob_revision),
                    original_asset_url: original_asset_url)
      whitehall_import = build(:whitehall_migration_document_import, assets: [asset])
      delete_request = stub_asset_manager_delete_asset(asset_id)

      described_class.call(whitehall_import)
      expect(delete_request).to have_been_requested
      expect(asset.state).to eq("removed")
    end
  end
end
