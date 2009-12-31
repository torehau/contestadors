class Predictable::Championship::PredictionsController < ApplicationController
  #defaults :route_prefix => nil, :resource_class => Group, :collection_name => 'groups', :instance_name => 'group'
  
  def new
    collection_type = params[:collection_type]
    collection_type ||= "group"
    collection_id = params[:collection_id]
    collection_id ||= "A"
    if collection_type.eql?("group")
      @group = Predictable::Championship::Group.find_by_name collection_id
    end
  end

  def create
  end

  def edit
  end

  def update
  end

end
