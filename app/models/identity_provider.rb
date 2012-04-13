class IdentityProvider < ActiveRecord::Base
  set_table_name "rpx_identifiers"
  belongs_to :user
end