desc 'Start IRB|Pry session with app initialized in background mode'
task console: :environment do
  if Settings.development?
    interpreter = Pry
  else
    require 'irb'
    require 'irb/completion'
    interpreter = IRB
  end

  # Is there a color support?
  if STDOUT.tty? && ENV['TERM'] != 'dumb'
    env_color = Settings.production? ? "\e[31m\e[1m" : "\e[36m\e[1m"
    puts "\e[32m\e[1m#{Settings.app_name}\e[0m\e[33m\e[1m::\e[0m\e[32m\e[1mConsole\e[0m " \
         "started in #{env_color}#{Settings.env}\e[0m environment."
  else
    puts "#{Settings.app_name}::Console started in #{Settings.env} environment."
  end

  ARGV.clear && ARGV.concat(['--prompt', 'simple'])
  interpreter.start
end
