module Core
  class User < ActiveRecord::Base
    set_table_name("core_users")
    acts_as_authentic
  end
end
