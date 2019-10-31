# frozen_string_literal: true

RSpec.describe Tasks::WhitehallImporter do
  let(:import_data) do
    {
      "id" => 1,
      "created_at" => Time.current,
      "updated_at" => Time.current,
      "slug" => "some-news-document",
      "content_id" => SecureRandom.uuid,
      "editions" => [
        {
          "id" => 1,
          "created_at" => Time.current,
          "updated_at" => Time.current,
          "change_note" => "First published",
          "state" => "draft",
          "translations" => [
            {
              "id" => 1,
              "locale" => "en",
              "title" => "Title",
              "summary" => "Summary",
              "body" => "Body",
            },
          ],
          "organisations" => [
            {
              "id" => 1,
              "content_id" => SecureRandom.uuid,
              "lead" => true,
              "lead_ordering" => 1,
            },
          ],
        },
      ],
    }
  end

  it "can import JSON data from Whitehall" do
    importer = Tasks::WhitehallImporter.new(123, import_data)

    expect { importer.import }.to change { Document.count }.by(1)

    imported_edition = import_data["editions"][0]
    edition = Edition.last

    expect(edition.summary)
      .to eq(imported_edition["translations"][0]["summary"])

    expect(edition.number).to eql(1)
    expect(edition.status).to be_draft
    expect(edition.update_type).to eq("major")
  end

  it "sets import_from as Whitehall" do
    importer = Tasks::WhitehallImporter.new(123, import_data)
    importer.import

    document = Document.last
    expect(document.imported_from_whitehall?).to be true
  end

  it "sets the correct states when Whitehall document state is 'published'" do
    import_data["editions"][0]["state"] = "published"
    importer = Tasks::WhitehallImporter.new(123, import_data)
    importer.import

    expect(Edition.last.status).to be_published
    expect(Edition.last).to be_live
  end

  it "can set minor update type" do
    import_data["editions"][0]["minor_change"] = true
    importer = Tasks::WhitehallImporter.new(123, import_data)
    importer.import

    expect(Edition.last.update_type).to eq("minor")
  end


  it "sets the correct states when Whitehall document is force published" do
    import_data["editions"][0]["state"] = "published"
    import_data["editions"][0]["force_published"] = true
    importer = Tasks::WhitehallImporter.new(123, import_data)
    importer.import

    expect(Edition.last.status).to be_published_but_needs_2i
    expect(Edition.last).to be_live
  end

  it "sets the correct states when Whitehall document state is 'rejected'" do
    import_data["editions"][0]["state"] = "rejected"
    importer = Tasks::WhitehallImporter.new(123, import_data)
    importer.import

    expect(Edition.last.status).to be_submitted_for_review
    expect(Edition.last).not_to be_live
  end

  it "sets the correct states when Whitehall document state is 'submitted'" do
    import_data["editions"][0]["state"] = "submitted"
    importer = Tasks::WhitehallImporter.new(123, import_data)
    importer.import

    expect(Edition.last.status).to be_submitted_for_review
    expect(Edition.last).not_to be_live
  end

  it "skips importing editions with Whitehall states that are not supported" do
    import_data["editions"][0]["state"] = "not_supported"
    importer = Tasks::WhitehallImporter.new(123, import_data)

    expect { importer.import }.not_to(change { Edition.count })
  end

  it "changes the ids of embedded contacts" do
    import_data["editions"][0]["translations"][0]["body"] = "[Contact:123]"
    content_id = SecureRandom.uuid
    import_data["editions"][0]["depended_upon_contacts"] = [{ "id" => 123, "content_id" => content_id }]
    importer = Tasks::WhitehallImporter.new(123, import_data)
    importer.import

    expect(Edition.last.contents["body"]).to eq("[Contact:#{content_id}]")
  end

  context "when importing organisation associations" do
    it "sets a primary_publishing_organisation" do
      importer = Tasks::WhitehallImporter.new(123, import_data)
      importer.import

      imported_organisation = import_data["editions"][0]["organisations"][0]
      edition = Edition.last

      expect(edition.primary_publishing_organisation_id).to eq(imported_organisation["content_id"])
    end

    it "rejects the import if there are no organisations" do
      import_data["editions"][0].delete("organisations")
      importer = Tasks::WhitehallImporter.new(123, import_data)

      expect { importer.import }.to raise_error(Tasks::AbortImportError)
    end

    it "rejects the import if there are no lead organisations" do
      import_data["editions"][0]["organisations"].shift
      importer = Tasks::WhitehallImporter.new(123, import_data)

      expect { importer.import }.to raise_error(Tasks::AbortImportError)
    end

    it "rejects the import if there is more than one lead organisation" do
      import_data["editions"][0]["organisations"].push(
        "id" => 3,
        "content_id" => SecureRandom.uuid,
        "lead" => true,
        "lead_ordering" => 2,
      )

      importer = Tasks::WhitehallImporter.new(123, import_data)

      expect { importer.import }.to raise_error(Tasks::AbortImportError)
    end
  end

  context "when an imported document has more than one edition" do
    let(:import_published_then_drafted_data) do
      {
        "id" => 1,
        "created_at" => Time.current,
        "updated_at" => Time.current,
        "slug" => "some-news-document",
        "content_id" => SecureRandom.uuid,
        "editions" => [
          {
            "id" => 1,
            "created_at" => Time.current,
            "updated_at" => Time.current,
            "title" => "Title",
            "summary" => "Summary",
            "change_note" => "First published",
            "state" => "published",
            "translations" => [
              {
                "id" => 1,
                "locale" => "en",
                "title" => "Title",
                "summary" => "Summary",
                "body" => "Body",
              },
            ],
            "organisations" => [
              {
                "id" => 1,
                "content_id" => SecureRandom.uuid,
                "lead" => true,
                "lead_ordering" => 1,
              },
            ],
          },
          {
            "id" => 2,
            "created_at" => Time.current,
            "updated_at" => Time.current,
            "title" => "Title",
            "summary" => "Summary",
            "change_note" => "First published",
            "state" => "draft",
            "translations" => [
              {
                "id" => 2,
                "locale" => "en",
                "title" => "Title",
                "summary" => "Summary",
                "body" => "Body",
              },
            ],
            "organisations" => [
              {
                "id" => 1,
                "content_id" => SecureRandom.uuid,
                "lead" => true,
                "lead_ordering" => 1,
              },
            ],
          },
        ],
      }
    end


    it "only creates the latest edition" do
      importer = Tasks::WhitehallImporter.new(123, import_published_then_drafted_data)
      importer.import

      expect(Edition.last.status).to be_draft
      expect(Edition.last).not_to be_live
    end

    it "sets imported to true on revision" do
      importer = Tasks::WhitehallImporter.new(123, import_published_then_drafted_data)
      importer.import

      expect(Revision.last.imported).to be true
    end
  end
end
