class RummagerDataPresenter
  def initialize(search_result)
    @search_result = search_result
  end

  def present!
    base_path     = @search_result["link"]
    organisations = fetch_resources("organisations", "/government/organisations/")
    people        = fetch_resources("people", "/government/people/")
    policies      = fetch_resources("policies")
    policy_groups = fetch_resources("policy_groups", '/government/groups/')
    specialist_sectors = fetch_resources("specialist_sectors", "/topic/")
    mainstream_browse_pages = fetch_resources("mainstream_browse_pages", "/browse/")

    rows = []

    rows << [base_path, 'policies', encode_array(policies)] if policies
    rows << [base_path, 'people', encode_array(people)] if people
    rows << [base_path, 'organisations', encode_array(organisations)] if organisations
    rows << [base_path, 'working_groups', encode_array(policy_groups)] if policy_groups
    rows << [base_path, 'topics', encode_array(specialist_sectors)] if specialist_sectors
    rows << [base_path, 'mainstream_browse_pages', encode_array(mainstream_browse_pages)] if mainstream_browse_pages

    rows
  end

private

  # Encode a ruby array as a postgres array literal eg {foo,bar,baz}
  def encode_array(resource)
    "{#{resource.join(',')}}"
  end

  def fetch_resources(resource_name, prefix = "")
    return nil if @search_result[resource_name].blank?

    unsorted = @search_result[resource_name].map do |resource|
      case resource
      when Hash
        resource["link"] if resource["link"].present?
      when String
        prefix + resource
      end
    end

    unsorted.sort
  end
end
