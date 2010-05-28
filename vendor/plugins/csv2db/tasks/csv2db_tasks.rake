namespace :csv2db do

  desc "Load data from CSV files to the database"
  task(:load_data => :environment) do
    dependencies = {}
    [Predictable::Championship::Team,
     Predictable::Championship::Player,
     Predictable::Championship::Stage,
     Predictable::Championship::Match,
     Predictable::Championship::StageTeam,
     Predictable::Championship::Group,
     Predictable::Championship::GroupTablePosition,
     Predictable::Championship::GroupQualification,
     Predictable::Championship::StageQualification,
     Configuration::Contest,
     Configuration::PredictionState,
     Configuration::Category,
     Configuration::Objective,
     Configuration::Set,
     Configuration::IncludedObjective,
     Configuration::IncludedSet,
     Configuration::PredictableItem,
     Prediction,
     PredictionSummary,
     User,
    ].each do |klass|
      klass.delete_all
      klass.load_from_csv(dependencies)
    end
  end

  desc "Load new users from the corresponding CSV file to the database"
  task(:add_users => :environment) do
    User.load_from_csv
  end

  desc "Updates existing database entries with new fields as given by the corresponding CSV file."
  task(:update_prediction_states => :environment) do
    Configuration::PredictionState.update_from_csv(:state_name, [:points_delta, :points_accumulated])
  end

  desc "Updates existing database entries with new match play datetime as given by the corresponding CSV file."
  task(:update_match_playtime => :environment) do
    Predictable::Championship::Match.update_from_csv(:id, [:play_date])
  end
end