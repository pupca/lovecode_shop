# Database related rake tasks
#
#   $ rake -T db
#   rake db:import_production  # Import database from production
#   rake db:import_stage       # Import database from staging
#   rake db:migrate[version]   # Run database migrations
namespace :db do
  desc 'Run database migrations'
  task :migrate, [:version] => [:environment] do |_, args|
    Sequel.extension :migration

    opts = {}

    if args[:version]
      puts "Migrating to version #{args[:version]}"
      opts[:target] = args[:version].to_i
    else
      puts 'Migrating to latest'
    end

    Sequel::Migrator.run(Settings.database, 'db/migrations', opts)
  end

  # desc 'Clean database'
  # task clean: :environment do
  #   User.all.collect {|u| u.destroy}
  #   Settings.database[:users].truncate
  #   Settings.database[:credentials].truncate
  #   Settings.database[:teams].truncate
  # end

  desc 'Reset database to its default state'
  task reset: :environment do
    Settings.database.run('DROP SCHEMA public CASCADE')
    Settings.database.run('CREATE SCHEMA public')
  end
end
