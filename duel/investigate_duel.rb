# frozen_string_literal: true

require_relative 'duel_helper'

# What RuboCop spends nearly all of its time on: a team of cops
# investigating a parsed file, through the Commissioner, which walks the
# AST once and calls each cop's callbacks. The file is parsed in `once`
# (parsing is rubocop-ast's and Prism's, the same in both versions), and
# the same team investigates it again on every iteration, as the runner
# reuses a team for every file with the same configuration.

duel 'investigate: every enabled cop on a 190-line file' do
  once do
    config = project_config
    @source = processed_source(CLEAN_FILE, config)
    @team = team(config)
  end
  @team.investigate(@source)
end

duel 'investigate: every enabled cop on a file with 82 offenses' do
  once do
    config = project_config
    @source = processed_source(MESSY_FILE, config)
    @team = team(config)
  end
  @team.investigate(@source)
end

%w[Layout Lint Metrics Naming Style].each do |department|
  duel "investigate: the #{department} cops on a 190-line file" do
    once do
      config = project_config
      @source = processed_source(CLEAN_FILE, config)
      @team = team(config, RuboCop::Cop::Registry.global.with_department(department.to_sym))
    end
    @team.investigate(@source)
  end
end

# The most expensive cops on the file, each alone. Lint/UselessAssignment
# runs the VariableForce, which tracks every variable's scope and
# references for several Lint cops at once.
%w[
  Layout/ExtraSpacing
  Layout/HashAlignment
  Layout/IndentationWidth
  Layout/LineLength
  Lint/UselessAssignment
  Metrics/AbcSize
  Style/MapIntoArray
  Style/RedundantSelf
].each do |cop_name|
  duel "investigate: #{cop_name} on a 190-line file" do
    once do
      config = project_config
      @source = processed_source(CLEAN_FILE, config)
      @team = cop_team(config, cop_name)
    end
    @team.investigate(@source)
  end
end

# The runner mobilizes a team once for each configuration: every enabled
# cop is instantiated with its configuration.
duel 'investigate: mobilize a team of every enabled cop' do
  once { @config = project_config.tap { |config| team(config) } }
  team(@config)
end
