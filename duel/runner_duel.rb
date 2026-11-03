# frozen_string_literal: true

require_relative 'duel_helper'

# A whole run of RuboCop on one file, as an editor or `rubocop --stdin`
# does it: finding the file's configuration, parsing it, investigating it,
# checking for redundant disable directives, autocorrecting until nothing
# changes, and reporting. The source comes from stdin, so nothing is read
# from or written to disk, and the result cache is off. The configuration
# is loaded once, as a server keeps it.

setup { @store = config_store }

duel 'runner: inspect a 190-line file' do
  once { @source = fixture(CLEAN_FILE) }
  run_rubocop(@store, CLEAN_FILE, @source)
end

duel 'runner: inspect a file with 22 disable directives' do
  # Directives on every method, none of them needed, so
  # Lint/RedundantCopDisableDirective reports each one.
  once do
    directive = ' # rubocop:disable Metrics/AbcSize'
    @source = fixture(CLEAN_FILE).gsub(/^ +def .*$/) { |line| line + directive }
  end
  run_rubocop(@store, CLEAN_FILE, @source)
end

duel 'autocorrect: the safe corrections of a messy file' do
  once { @source = fixture(MESSY_FILE) }
  run_rubocop(@store, MESSY_FILE, @source, autocorrect: true, safe_autocorrect: true)
end

duel 'autocorrect: the layout corrections of a messy file' do
  once { @source = fixture(MESSY_FILE) }
  run_rubocop(@store, MESSY_FILE, @source, autocorrect: true, only: ['Layout'])
end
