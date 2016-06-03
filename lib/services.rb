module Services
  def self.publishing_api
    @publishing_api ||= with_retries(
      GdsApi::PublishingApiV2.new(Plek.new.find('publishing-api'),
        bearer_token: ENV['PUBLISHING_API_BEARER_TOKEN'] || 'example',
        timeout: 20,
        disable_cache: true,
    ))
  end

  def self.rummager
    @rummager ||= with_retries(
      GdsApi::Rummager.new(Plek.new.find('rummager'),
        timeout: 20,
        disable_cache: true,
    ))
  end

  def self.with_retries(target)
    RetryWrapper.new(target: target, maximum_number_of_attempts: 5)
  end

  class RetryWrapper
    def initialize(target:, maximum_number_of_attempts:)
      @target = target
      @maximum_number_of_attempts = maximum_number_of_attempts
    end

    def method_missing(method_sym, *arguments, &block)
      attempts = 0
      begin
        attempts += 1
        @target.public_send(method_sym, *arguments, &block)
      rescue Timeout::Error, GdsApi::TimedOutException, GdsApi::HTTPServerError => e
        raise e if attempts >= @maximum_number_of_attempts
        sleep sleep_time_after_attempt(attempts)
        retry
      end
    end

    def sleep_time_after_attempt(current_attempt)
      current_attempt
    end
  end
end

# This will move to gds-api-adapters once we have a generalised use case.
class GdsApi::PublishingApiV2
  def get_grouped_content_and_links(last_seen_content_id: nil, page_size: nil)
    params = {}
    params["last_seen_content_id"] = last_seen_content_id unless last_seen_content_id.nil?
    params["page_size"] = page_size unless page_size.nil?

    query = query_string(params)

    get_json!("#{endpoint}/v2/grouped-content-and-links#{query}")
  end
end
