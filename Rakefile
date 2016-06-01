require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

desc "Run govuk-lint with similar params to CI"
task "lint" do
  sh "bundle exec govuk-lint-ruby --format clang Gemfile lib spec Rakefile"
end

task default: [:spec, :lint]
