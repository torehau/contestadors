module Predictable
  module Championship
    # For validating predicted group match results, which must be on the form
    # n-m, where n and m must be an integer in the range 0..99
    class GroupMatchesValidator
      include Ruleby

      def initialize
        @errors = {}
      end

      def validate(group)
        
        if group

          engine :group_matches do |e|
            rulebook = GroupMatchesValidationRulebook.new(e)
            rulebook.rules
            rulebook.errors = @errors

            group.matches.each{|group_match| e.assert group_match}

            e.match
          end
        end
        @errors
      end

      private

      class GroupMatchesValidationRulebook < Ruleby::Rulebook

        attr_accessor :errors

        def rules
          rule :invalid_score,
             OR ([Predictable::Championship::Match, :gm, m.home_team_score(&c{|hts| !is_valid_score?(hts)})],
                 [Predictable::Championship::Match, :gm, m.away_team_score(&c{|ats| !is_valid_score?(ats)})]) do |v|
             
               @errors[v[:gm].id] = v[:gm].home_team_score + '-' + v[:gm].away_team_score
               retract v[:gm]
             end
        end

        private

        # Checks that the input str is in the valid numeric format and within the range 0..99
        def is_valid_score?(score_str)
          return false if score_str.nil? or not (1..2).include?(score_str.length)
          return false if score_str.length == 2 and score_str[0,1].eql?("0")
          is_non_negative_integer?(score_str)
        end

        def is_non_negative_integer?(str_value)
          begin
            score_int = Integer(str_value)
          rescue ArgumentError => e
            return false
          else
            return score_int >= 0
          end
        end
      end
    end
  end
end