# frozen_string_literal: true

begin
  require 'duel/rake_task'

  # Compares the working tree with where it left master, on the benchmarks
  # in duel/.
  Duel::RakeTask.new
rescue LoadError
  # Duel requires Ruby 3.4 or later.
end
