# frozen_string_literal: true

require 'stringio'

# The fixtures are fixed Ruby files and configuration, under duel/, so
# both versions inspect the same input. Each benchmark builds what it
# needs in `once`, which Duel doesn't time.
FIXTURES = File.expand_path('fixtures', __dir__)

# A tidy, 190-line class of the kind most files are, with a few offenses.
CLEAN_FILE = File.join(FIXTURES, 'inventory.rb')
# A 90-line file that breaks a lot of the style guide, for autocorrect.
MESSY_FILE = File.join(FIXTURES, 'report.rb')
# A project's .rubocop.yml, which inherits from two more files. Each of
# them sets TargetRubyVersion, so finding the target Ruby never reads a
# file outside duel/, such as the repository's gemspec, or a lockfile or
# .ruby-version that only the working tree has.
CONFIG_FILE = File.join(FIXTURES, 'config', 'rubocop.yml')

def fixture(path)
  File.read(path)
end

def project_config
  config = RuboCop::ConfigLoader.load_file(CONFIG_FILE)
  RuboCop::ConfigLoader.merge_with_default(config, CONFIG_FILE)
end

def processed_source(path, config, source: fixture(path))
  processed_source = RuboCop::ProcessedSource.new(
    source, config.target_ruby_version, path, parser_engine: config.parser_engine
  )
  processed_source.config = config
  processed_source.registry = RuboCop::Cop::Registry.global
  processed_source
end

# A team of the cops in the registry that the configuration enables, as
# the runner mobilizes it.
def team(config, registry = RuboCop::Cop::Registry.global)
  RuboCop::Cop::Team.mobilize(registry, config)
end

def cop_team(config, cop_name)
  team(config, RuboCop::Cop::Registry.new([RuboCop::Cop::Registry.global.find_by_cop_name(cop_name)]))
end

def config_store
  RuboCop::ConfigStore.new.tap { |store| store.options_config = CONFIG_FILE }
end

# Runs RuboCop on one file whose source comes from stdin, as an editor
# does, with the result cache off and the report going nowhere. Returns
# the source after any corrections.
def run_rubocop(store, path, source, **options)
  options = { stdin: source.dup, cache: 'false', formatters: [['progress', File::NULL]], **options }
  RuboCop::Runner.new(options, store).run([path])
  options[:stdin]
end

# The offenses of the default cops in a file, for the formatters.
def offenses_of(path, config)
  team(config).investigate(processed_source(path, config)).offenses.sort
end

# Reports offenses to a formatter, as the runner does for one file.
def report(formatter_class, path, offenses)
  output = StringIO.new
  formatter = formatter_class.new(output)
  formatter.started([path])
  formatter.file_started(path, {})
  formatter.file_finished(path, offenses)
  formatter.finished([path])
  output.string
end
