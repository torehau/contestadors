namespace :csv2db do

  desc "Load data from CSV files to the database"
  task (:load_data => :environment) do
    dependencies = {}
    [Configuration::Category,
     Configuration::Objective,
     Configuration::Set,
     Configuration::IncludedObjective,
     Configuration::Contest,
     Configuration::IncludedSet,
     Predictable::Championship::Team,
     Predictable::Championship::Player,
     Predictable::Championship::Stage,
     Predictable::Championship::Match,
     Predictable::Championship::StageTeam,
     Predictable::Championship::Group,
     Predictable::Championship::GroupTablePosition,
     Configuration::PredictableItem,
     Core::User
    ].each do |klass|
      klass.delete_all
      klass.load_from_csv(dependencies)
    end
  end

end