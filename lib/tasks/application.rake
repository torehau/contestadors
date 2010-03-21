namespace :app do

  desc "Resets the database, migrates it to current version and loads all static date"
  task(:setup) do
    puts "dropping database..."
    Rake::Task["db:drop:all"].invoke
    puts "recreateing database..."
    Rake::Task["db:create:all"].invoke
    puts "migrating database schema..."
    Rake::Task["db:migrate"].invoke
    puts "loading data from csv files..."
    Rake::Task["csv2db:load_data"].invoke
  end
end