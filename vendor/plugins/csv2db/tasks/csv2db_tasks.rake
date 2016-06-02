namespace :csv2db do

  desc "Load data from CSV files to the database"
  task(:load_data => :environment) do
    dependencies = {}
    [Configuration::Contest,
     Predictable::Championship::Team,
     Predictable::Championship::Player,
     Predictable::Championship::Stage,
     Predictable::Championship::Match,
     Predictable::Championship::StageTeam,
     Predictable::Championship::Group,
     Predictable::Championship::GroupTablePosition,
     Predictable::Championship::GroupQualification,
     Predictable::Championship::StageQualification,
     Predictable::Championship::BestRankedGroup,
     Predictable::Championship::ThirdPlaceGroupTeamQualification,
     Configuration::PredictionState,
     Configuration::Category,
     Configuration::Objective,
     Configuration::Set,
     Configuration::IncludedObjective,
     Configuration::IncludedSet,
     Configuration::PredictableItem,
#     Prediction,
     #     PredictionSummary,
     User
    ].each do |klass|
      klass.delete_all
      klass.load_from_csv(dependencies)
    end
  end

  desc "Adds a new championship contest from CSV files to the database"
  task(:add_championship_contest => :environment) do
    dependencies = Configuration::Category.dependency_csv_id_by_db_id_map

    [Configuration::Contest,
     Predictable::Championship::Team,
     Predictable::Championship::Stage,
     Predictable::Championship::Match,
     Predictable::Championship::StageTeam,
     Predictable::Championship::Group,
     Predictable::Championship::GroupTablePosition,
     Predictable::Championship::GroupQualification,
     Predictable::Championship::StageQualification,
     Configuration::PredictionState,
     Configuration::Objective,
     Configuration::Set,
     Configuration::IncludedObjective,
     Configuration::IncludedSet,
     Configuration::PredictableItem
    ].each do |klass|
      klass.load_from_csv(dependencies)
    end
  end

  desc "Load new users from the corresponding CSV file to the database"
  task(:add_users => :environment) do
    User.load_from_csv
  end

  desc "Updates existing database entries with new fields as given by the corresponding CSV file."
  task(:update_prediction_states => :environment) do
    Configuration::PredictionState.update_from_csv(:state_name, [:permalink, :points_delta, :points_accumulated, :preview_available, :position])
  end

  desc "Updates existing database entries with new match play datetime as given by the corresponding CSV file."
  task(:update_match_playtime => :environment) do
    Predictable::Championship::Match.update_from_csv(:id, [:play_date])
  end

  desc "Updates existing database entries with new match play datetime as given by the corresponding CSV file."
  task(:update_teams => :environment) do
    Predictable::Championship::Team.update_from_csv(:id, [:country_flag, :name])
  end

  desc "Updates existing teams with the given ranking coefficient positions."
  task(:set_team_ranking_positions => :environment) do
    filename = $csv_dir + 'ranking_coefficients.csv'
    parser = CSV.new(File.open(filename, 'r'),
                           :headers => true, :header_converters => :symbol,
                           :col_sep => ',')
    parser.each do |row|
      if row and row.length > 0 and row.include?(:name)
        name = row.field(:name)
        puts "Setting rank position for " + name
        team = Predictable::Championship::Team.where(:name => name).last
        team.ranking_coefficient = row.field(:ranking_coefficient)
        team.save!
        puts " rank set to " + team.ranking_coefficient.to_s
      end
    end
  end
end