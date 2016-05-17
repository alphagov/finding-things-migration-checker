module Checks
  class Report

    attr_reader :name, :success, :summary, :csv

    def initialize(name:, success:, summary:, csv:)
      @name = name
      @success = success
      @summary = summary
      @csv = csv
    end
  end
end
