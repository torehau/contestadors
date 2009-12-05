require 'test_helper'

class Predictable::Championship::MatchTest < ActiveSupport::TestCase

  def setup
    ActiveRecord::Base.send(:include, Csv2Db::DataLoader)

    # Specify the folder where the csv data files will be located, and store the path in the $csv_dir global variable
    path = File.join(File.dirname(__FILE__), '../../../../vendor/plugins/csv2db/csv')
    $csv_dir = path  + '/'

    dependencies = {}
    [Predictable::Championship::Team,
     Predictable::Championship::Stage,
     Predictable::Championship::Match
    ].each do |klass|
      klass.delete_all
      klass.load_from_csv(dependencies)
    end
  end

  def map_by_stage(matches)
    stage_to_matches = {}
    matches.each do |match|
      stage = match.stage.description.to_sym
      if stage_to_matches.has_key? stage
        stage_to_matches[stage] << match
      else
        stage_to_matches[stage] = [match]
      end
    end
    stage_to_matches
  end

  # Tests that the first match is South Africa - Mexico, and that it is a group match
  test "championship matches" do
    matches = Predictable::Championship::Match.find(:all)
    assert_equal 64, matches.size
    opening_match(matches.first)    
    stage_to_matches = map_by_stage(matches)
    assert_equal 48, stage_to_matches["Group".to_sym].length
    assert_equal 8, stage_to_matches["Round of 16".to_sym].length
    assert_equal 4, stage_to_matches["Quarter-finals".to_sym].length
    assert_equal 2, stage_to_matches["Semi-finals".to_sym].length
    assert_equal 1, stage_to_matches["Third place play-off".to_sym].length
    assert_equal 1, stage_to_matches["Final".to_sym].length
  end



  def opening_match(opening_match)
    assert_equal "South Africa", opening_match.home_team.name
    assert_equal "Mexico", opening_match.away_team.name
    assert_equal "Group", opening_match.stage.description
  end

  def final_match
    # todo
  end
end
