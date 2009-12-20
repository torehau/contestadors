require 'fastercsv'

# Plugin for loading data from CSV files into the database. The data files must be located in the csv directory of the plugin.
module Csv2Db
  module DataLoader
    def self.included(base)
      base.extend SingletonMethods
    end

    module ClassMethods
      #include InstanceMethods
     # extend SingletonMethods
    end

#     module InstanceMethods
#     end

    module SingletonMethods
      # List specifying all fields that shall not be migrated from the CSV files to the DB. Typical for columns where it
      # is sensible to let the database set default values - ids and timestamps.
      IGNORE_FIELD_LIST = [:id, :created_at, :updated_at]

      # List specifying all fields that should be read and formatted as a datetime field
      DATE_FIELD_LIST = [:available_from, :available_to, :participation_ends_at, :play_date, :last_request_at, :last_login_at, :current_login_at]

      # Nested hash allowing all entries of the corresponding field to be substituted with value of another field
      SUBSTITUTE_FIELDS = {:core_users => {:password_salt => :password, :crypted_password => :password_confirmation}}

      # Nested hash allowing all entries of the corresponding field to be substituted with the given value
      SUBSTITUTE_FIELD_VALUES = {:users => {:ignore_password_salt => "hERt50Pd", :ignore_password_hash => "8a335fca75392a2f5d0e850a313c62ac8ce6753f6d78070bc34a6c61279874a0"}}

      # Map of foreign id keys not complying with the conventional rails naming, i.e., when the id column is not on the form <table_name>_id 
      FOREIGN_ID_KEY_MAP = {:home_team_id => :predictable_championship_teams, :away_team_id => :predictable_championship_teams}

      # dependencies       a nested hash to be populated with the table_name as key. For each table
      #                    there will be a nested hash with the id from the CSV file as key, and the
      #                    new id assigned by the DB as the value
      def load_from_csv(dependencies={})

        parser = FasterCSV.new(File.open(filename(), 'r'),
                               :headers => true, :header_converters => :symbol,
                               :col_sep => ',')
        convert_date_fields(parser)
        csv_id_to_db_id_map = {}
        substitute_values = substitute_field_values

        parser.each do |row|
          if row and row.length > 0 and row.include?(:id)
            csv_id = row.field(:id)
            instance = create_new_instance_from_row(dependencies, row, substitute_values)
            instance.save!
            csv_id_to_db_id_map[csv_id] = instance.id
          end
        end
        puts csv_id_to_db_id_map.length.to_s + " new entries stored in table: " + self.table_name
        dependencies[self.table_name.to_sym] = csv_id_to_db_id_map
      end

      def filename
        $csv_dir + self.table_name + '.csv'
      end

      # Converts any date column types given by the csv to the DateTime format needed by the database
      def convert_date_fields(parser)
        parser.convert do |field, info|
          DATE_FIELD_LIST.include?(info.header) ? DateTime.parse(field) : field
        end
      end


      # gets the hash of fields for which the values shall be substituted
      def substitute_field_values
        substitute_values = SUBSTITUTE_FIELD_VALUES[self.name.pluralize.split('::').last]
        substitute_values ||= {}
        substitute_values
      end

      # Creates a new instance of the class represented by the CSV row, populating it with the provided attribute values.
      def create_new_instance_from_row(dependencies, row, substitute_values)
        instance = new
        
        substitute_fields = SUBSTITUTE_FIELDS[instance.class.table_name.to_sym]

        instance.attribute_names.each do |attr_name|
          
          unless IGNORE_FIELD_LIST.include?(attr_name.to_sym)
            field_name = attr_name
            field_name =  substitute_fields[attr_name.to_sym].to_s if substitute_fields and substitute_fields.has_key?(attr_name.to_sym)
            value = row.field(field_name.to_sym)

            if value

              if attr_name.include?("_id")
                dependant_table_name = attr_name.sub("_id", "").pluralize

                if dependencies[dependant_table_name.to_sym]
                  value = dependencies[dependant_table_name.to_sym][value]
                else
                  value = resolve_id_value(attr_name.to_sym, value, dependencies, instance)
                end
              elsif substitute_values.has_key?(attr_name.to_sym)
                value = substitute_values[attr_name.to_sym]
              end

              instance.try((field_name+"=").to_sym, value)
            end
          end
        end
        return instance
      end

      # Contestadors specific method assuming the class with a predictable_id column to have a predictable_table
      # method returning the table name of the actual predictable type
      def resolve_id_value(column_name, id_value, dependencies, instance)
        if column_name.eql?(:predictable_id)
           if id_value == 0
             puts "Predictable id 0" + self.predictable_table
             return 0
           else
             puts "Predictable id of " + instance.predictable_table
             return dependencies[instance.predictable_table.to_sym][id_value]
           end
        else
          return dependencies[FOREIGN_ID_KEY_MAP[column_name.to_sym]][id_value]
        end
      end
    end
  end
end