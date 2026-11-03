# frozen_string_literal: true

require_relative 'duel_helper'

# Reporting the 82 offenses of a messy file, to memory.

setup { @offenses = offenses_of(MESSY_FILE, project_config) }

{
  'progress' => RuboCop::Formatter::ProgressFormatter,
  'json' => RuboCop::Formatter::JSONFormatter,
  'github' => RuboCop::Formatter::GitHubActionsFormatter,
  'offenses' => RuboCop::Formatter::OffenseCountFormatter
}.each do |name, formatter_class|
  duel "formatter: report 82 offenses with the #{name} formatter" do
    report(formatter_class, MESSY_FILE, @offenses)
  end
end
