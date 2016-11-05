ENV['POOL_SIZE'] = '1'
ENV['NEWRELIC_AGENT_ENABLED'] = 'false'

# Setup application environment
task :environment do
  require_relative 'rake_init'
end

# Run console as default task
task default: [:console]

##############
# TASK HELPERS
##############

# Print and run the command (unless dryrun).
#
# @param [String] verbose
def run_command(command, opts = {})
  opts[:verbose] ||= true

  require 'bundler' unless defined?(Bundler)

  Bundler.with_clean_env do
    verbose opts[:verbose] do
      sh command
    end
  end
end

# Ask a question on the command line.
# +y+ or +n+ returns +true+ and +false+.
# +q+ exits the program.
#
#   ask 'Feeling good?' do
#     FileUtils.cp('a', 'b', verbose: true)
#     run_command 'ls'
#   end
#
# @param [String] question
#
# @return [Bool]
def ask(question)
  loop do
    print "\e[33m\e[1m#{question}\e[0m [\e[32myNq\e[0m]: "

    case STDIN.gets.strip.downcase
    when 'y'
      yield if block_given?
      return true
    when 'n'
      return false
    when 'q'
      exit
    end
  end
end

##############
# TASKS IMPORT
##############

Dir['./tasks/*.rake'].each { |task| import task }
