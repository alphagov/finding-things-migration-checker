require 'import/publishing_api_data_presenter'

module Import
  RSpec.describe PublishingApiDataPresenter do

    it "presents links from publishing-api in a form suitable for insertion in the local sqlite db" do

      content_id_data = test_data_example

      expected_rows = [
          ["00015d3f-e7d9-48e8-95ff-ac3f7fa07be3", "organisations", "6667cce2-e809-4e21-ae09-cb0bdc1ddda3"],
          ["00015d3f-e7d9-48e8-95ff-ac3f7fa07be3", "policy_areas", "8034be95-4ac2-4fff-93c5-e7514ed9504a"],
          ["00015d3f-e7d9-48e8-95ff-ac3f7fa07be3", "policy_areas", "6667cce2-e809-4e21-ae09-cb0bdc1ddda3"],
      ]

      rows = PublishingApiDataPresenter.present_links(content_id_data)

      expect(rows).to eq(expected_rows)
    end

    it "presents content from publishing-api in a form suitable for insertion in the local sqlite db" do

      content_id_data = test_data_example

      expected_row = ["00015d3f-e7d9-48e8-95ff-ac3f7fa07be3", "whitehall", "statistics_announcement", 'published_at_least_once']

      row = PublishingApiDataPresenter.present_content(content_id_data)

      expect(row).to eq(expected_row)
    end

  private
    def test_data_example
      {
          'content_id' => "00015d3f-e7d9-48e8-95ff-ac3f7fa07be3",
          'content_items' => [
              {
                  'base_path' => "/government/statistics/announcements/some-statistics-page",
                  'format' => "statistics_announcement",
                  'locale' => "en",
                  'publishing_app' => "whitehall",
                  'state' => "published",
                  'user_facing_version' => "2"
              },
              {
                  'base_path' => "/government/statistics/announcements/another-statistics-page",
                  'format' => "statistics_announcement",
                  'locale' => "en",
                  'publishing_app' => "whitehall",
                  'state' => "superseded",
                  'user_facing_version' => "1"
              }
          ],
          'links' => {
              'organisations' => [
                  "6667cce2-e809-4e21-ae09-cb0bdc1ddda3",
              ],
              'policy_areas' => [
                  "8034be95-4ac2-4fff-93c5-e7514ed9504a",
                  "6667cce2-e809-4e21-ae09-cb0bdc1ddda3",
              ]
          }
      }
    end
  end
end
