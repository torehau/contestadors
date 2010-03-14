module Predictable
  module Championship

    # Container class for predictions that are to be displayed on the same page
    # and saved to the db in the same transaction.
    class Aggregate
      # the user to whom the predictions in the aggregate belongs
      attr_accessor :user
      # the type of the aggregate root, curently supported :group and :stage
      attr_accessor :type
      # the aggregate root object
      attr_accessor :root
      # hash of new or updated predicted values keyed by the predictable id (e.g., match id)
      attr_accessor :new_predictions, :has_existing_predictions
      # group aggregate specific accessors
      attr_accessor :operation, :command, :member_id 
      # stage aggregate specific
      attr_accessor :all_roots, :all_predicted_roots, :all_invalidated_roots, :associated

      def initialize(user, params)
        @user = user        
        @type = params[:aggregate_root_type].to_sym
        @id = params[:aggregate_root_id]
        @operation = params[:operation]
        @command = params[:command].to_sym if params.has_key?(:command)
        @member_id = params[:id].to_i if params.has_key?(:id)        
        @new_predictions = params[@type] ? params[@type][:new_predictions] : nil
        @has_new_predictions = (@new_predictions and not @new_predictions.empty?)
        @has_existing_predictions = false
        @all_invalidated_roots = []
      end

      def id
        id = @id

        if @root

          if @type.eql?(:stage)
            id = @root.permalink
          elsif @type.eql?(:group)
            id = @root.name
          end
        end
        id
      end

      def set_root_from_existing_predictions(root)
        if root
          @root = root
          @has_existing_predictions = true
        end
      end

      def is_predicted?
        [@has_existing_predictions, @has_new_predictions].include?(true)
      end

      # to check whether there are no prior predictions for this aggregate
      def is_new_predictions?
        (@has_existing_predictions == false and @has_new_predictions == true)
      end

      def is_rearrangable?
        (@type.eql?(:group) and !@user.nil? and @root.is_rearrangable?)
      end

      def validation_errors=(validation_errors)
        @validation_errors = validation_errors
      end

      def has_validation_errors?
        (@validation_errors and @validation_errors.size > 0)
      end

      def has_validation_error_for?(predictable_id)
        (has_validation_errors? and @validation_errors.has_key?(predictable_id))
      end

      def is_editing_existing_predictions?
        return false unless @operation
        'edit'.eql?(@operation)
      end
    end
  end
end
