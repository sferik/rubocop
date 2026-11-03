# frozen_string_literal: true

require_relative 'duel_helper'

# Every run loads the default configuration and the project's, and
# merges them, before it inspects anything.

duel 'config: load config/default.yml' do
  RuboCop::ConfigLoader.load_file(RuboCop::ConfigLoader::DEFAULT_FILE)
end

duel 'config: load a .rubocop.yml that inherits from two files' do
  RuboCop::ConfigLoader.load_file(CONFIG_FILE)
end

duel 'config: merge a .rubocop.yml with the default configuration' do
  once { @config = RuboCop::ConfigLoader.load_file(CONFIG_FILE) }
  RuboCop::ConfigLoader.merge_with_default(@config, CONFIG_FILE)
end

duel 'config: find the enabled cops for a configuration' do
  once { @config = project_config }
  RuboCop::Cop::Registry.global.enabled(@config)
end
