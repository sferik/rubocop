# frozen_string_literal: true

# Duel's configuration: https://github.com/sferik/duel-ruby/blob/main/docs/configuration.md
#
# Duel follows conventions, so set only what differs: benchmarks are in
# duel/**/*_duel.rb, each version's lib/ is first on the load path, a
# change is compared when it touches lib/ or ext/ (or the benchmarks, or
# this file), and releases are tagged v*.
Duel.configure do |c|
  # The library each version's workers require (from the gemspec, unless
  # this says otherwise).
  # c.library = "rubocop"

  # Compare a change to config/ too: every run loads and merges
  # config/default.yml, and its settings decide which cops run.
  c.watch += %w[config]

  # When the workflow comments on a pull request with the report: :always,
  # :results (passed or failed), :failures (failed, or couldn't compare),
  # or :never.
  # c.comment = :failures

  # Which runs a regression fails: :every_run, or :pull_requests, for a
  # project where people push to master directly (on GitHub Actions, another
  # run warns and passes, and a pushed commit gets the comment instead).
  # c.fail_on = :every_run

  # A label that accepts a regression in a pull request (nil for none).
  # c.accept_label = "duel: accept"

  # What the workflow compares a push with: :before (the commit before it),
  # or :last_passed (the last commit Duel passed, which a branch,
  # duel/passed/master, marks), so small slowdowns add up until they fail.
  # c.push_base = :before
end
