module Predictable
  module Championship

    class RepositoryFactory

      def self.create(aggregate=nil)
        return Repository.new unless aggregate
        repository = nil

        if aggregate.type.eql?(:group)
          repository = GroupRepository.new(aggregate)
        elsif aggregate.type.eql?(:stage)
          repository = StageRepository.new(aggregate)
        end
        repository
      end
    end
  end
end
