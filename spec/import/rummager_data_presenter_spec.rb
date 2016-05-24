require 'import/rummager_data_presenter'

module Import
  RSpec.describe RummagerDataPresenter do

    it "presents links from rummager in a form suitable for insertion in the local sqlite db" do

      row_data = test_data_example

      expected_rows = [
          ["/vehicle-tax", "organisations", "/government/organisations/driver-and-vehicle-licensing-agency"],
          ["/vehicle-tax", "organisations", "/government/organisations/test-org"],
          ["/vehicle-tax", "mainstream_browse_pages", "/browse/driving/car-tax-discs"],
      ]

      rows = RummagerDataPresenter.present_links(row_data)

      expect(rows).to eq(expected_rows)
    end

    it "presents content from rummager in a form suitable for insertion in the local sqlite db" do

      batch_data = [test_data_example]

      expected_rows = [
          ['/vehicle-tax', nil, 'transaction', 'mainstream', 'edition'],
      ]

      rows = RummagerDataPresenter.present_content(batch_data)

      expect(rows).to eq(expected_rows)
    end


    private
    def test_data_example
      {
        'link' => "/vehicle-tax",
        'mainstream_browse_pages' => ["driving/car-tax-discs"],
        'organisations' => [
          {
            'slug' => "driver-and-vehicle-licensing-agency",
            'title' => "Driver and Vehicle Licensing Agency",
            'acronym' => "DVLA",
            'organisation_state' => "live",
            'link' => "/government/organisations/driver-and-vehicle-licensing-agency"
          },
          {
            'slug' => "test-org",
            'title' => "Test Org",
            'acronym' => "TO",
            'organisation_state' => "live",
            'link' => "/government/organisations/test-org"
          },
        ],
        'document_type' => 'edition',
        'format' => 'transaction',
        'index' => 'mainstream',
      }
    end
  end
end
