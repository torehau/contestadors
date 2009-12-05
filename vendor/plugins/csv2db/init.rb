require 'csv2db.rb'
# Mix in the Csv2DB::DataLoader module in ActiveRecord::Base
ActiveRecord::Base.send(:include, Csv2Db::DataLoader)

# Specify the folder where the csv data files will be located, and store the path in the $csv_dir global variable
path = File.join(File.dirname(__FILE__), 'csv')
$csv_dir = path  + '/'
