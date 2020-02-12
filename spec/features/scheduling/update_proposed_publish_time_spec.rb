RSpec.describe "Update proposed publish time" do
  around do |example|
    travel_to(Time.zone.parse("2019-06-13")) { example.run }
  end

  it do
    given_there_is_a_schedulable_edition
    when_i_visit_the_summary_page
    and_i_click_on_change_date
    then_i_see_the_proposed_time

    when_i_set_a_new_time
    then_i_see_the_new_proposed_time
  end

  def given_there_is_a_schedulable_edition
    publish_time = Time.zone.parse("2019-06-14 10:00")
    @edition = create(:edition, proposed_publish_time: publish_time)
  end

  def when_i_visit_the_summary_page
    visit document_path(@edition.document)
  end

  def and_i_click_on_change_date
    click_on "Change date"
  end

  def then_i_see_the_proposed_time
    expect(find_field("schedule[date][day]").value).to eq "14"
    expect(find_field("schedule[date][month]").value).to eq "6"
    expect(find_field("schedule[date][year]").value).to eq "2019"
    expect(find_field("schedule[time]").value).to eq "10:00am"
  end

  def when_i_set_a_new_time
    fill_in "schedule[date][day]", with: "15"
    fill_in "schedule[date][month]", with: "6"
    fill_in "schedule[date][year]", with: "2019"
    fill_in "schedule[time]", with: "11:00pm"
    click_on "Save date"
  end

  def then_i_see_the_new_proposed_time
    expect(page)
      .to have_content(I18n.t!("documents.show.proposed_scheduling_notice.title",
                               time: "11:00pm",
                               date: "15 June 2019"))
  end
end
