module Predictable
  module Championship
    class CommonContestCategoryItemsResolver

      def resolve(contest, categories)
        #["Stage Teams", "Specific Team"].collect{|category_descr| Configuration::Category.find_by_description(category_descr)}.collect{|category| category.predictable_items}.flatten
        category_sets = Configuration::Category.where(:description => categories).collect{|category| category.sets}.flatten
        contest_sets = contest.sets
        (category_sets & contest_sets).collect{|set| set.predictable_items}.flatten
      end
    end
  end
end
