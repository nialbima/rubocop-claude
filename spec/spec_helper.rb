# frozen_string_literal: true

# Coverage reporting (must be loaded before application code)
require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
  enable_coverage :branch
end

require "rubocop"
require "rubocop/rspec/support"
require "rubocop-claude"

RSpec.configure do |config|
  config.include RuboCop::RSpec::ExpectOffense

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.warnings = true

  config.default_formatter = "doc" if config.files_to_run.one?

  config.order = :random
  Kernel.srand config.seed
end

RSpec.shared_context "config" do
  let(:config) do
    # Merge cop-specific config into a base config
    hash = { "AllCops" => { "TargetRubyVersion" => 3.1 } }
    hash.merge!(cop_config) if respond_to?(:cop_config)
    RuboCop::Config.new(hash, "#{Dir.pwd}/.rubocop.yml")
  end
end

RSpec.configure do |config|
  config.include_context "config", :config
end
