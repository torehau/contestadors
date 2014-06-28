class CommentsController < ApplicationController
  include ContestContext, ContestAccessChecker
  strip_tags_from_params :only =>  [:create, :update]
  before_filter :redirect_if_under_maintenance
  before_filter :require_user
  before_filter :set_context_from_request_params
  before_filter :require_participation
  before_filter :require_admin, :only => :update
  
  def index
    @no_comments_for_contest = @contest_instance.root_comments.size == 0    
    conditions = {:commentable_id => @contest_instance.id, :parent_id => nil, :blocked => false}
    conditions[:removed] = false unless current_user.is_admin_of?(@contest_instance)
	@comments_grid = initialize_grid(Comment,
	    :include => [:user],
	    :conditions => conditions,
	    :order => 'created_at',
        :order_direction => 'desc',
	    :per_page => 10)      	
  end
  
  def new
    @comment = Comment.new
    flash[:notice] = "Create a new comment that will be visible for participants of the '#{@contest_instance.name}' contest"
  end
  
  def show
    @comment = Comment.find(params[:id])
    
    if @comment.commentable_id != @contest_instance.id
      flash[:alert] = "The comment is not available for this contest."
      redirect_to contest_comments_path(:contest => @contest.permalink, :role => "admin", :contest_id => @contest_instance.permalink, :uuid => @contest_instance.uuid)    
    elsif @comment.blocked? or @comment.removed?
      flash[:alert] = "The comment is no longer available. It might have been removed by the author, contest administrator or system admin."
      redirect_to contest_comments_path(:contest => @contest.permalink, :role => "admin", :contest_id => @contest_instance.permalink, :uuid => @contest_instance.uuid)
    else
      @reply = Comment.new
    end
  end
  
  # For removing - allowed for contest instance admin users only
  def update
    @comment = Comment.find(params[:id])

    respond_to do |format|
      if @comment.update_attributes(params[:comment])
        format.html {redirect_to contest_comments_path(:contest => @contest.permalink, :role => "admin", :contest_id => @contest_instance.permalink, :uuid => @contest_instance.uuid)}
        format.js { head :ok}
      else
        format.html {redirect_to contest_comments_path(:contest => @contest.permalink, :role => "admin", :contest_id => @contest_instance.permalink, :uuid => @contest_instance.uuid)}
        format.js { head :unprocessable_entity}
      end
    end
  end
  
  def create
	@comment_hash = params[:comment]
	@comment = Comment.build_from(@contest_instance, current_user.id, @comment_hash[:body])
	@comment.title = @comment_hash[:title]
	@comment.removed = false
	@comment.blocked = false
	@is_reply = !params[:parent_id].nil?
	
	if @is_reply
	  @comment.parent_id = params[:parent_id].to_i
	end

	if @comment.save
	  flash[:notice] = @is_reply ? "Your reply was successfully saved!" : "Your comment was successfully created!"
	  redirect_to @is_reply ? contest_comment_path(:contest => @contest.permalink, :role => "admin", :contest_id => @contest_instance.permalink, :uuid => @contest_instance.uuid, :id => @comment.parent_id)
	    : contest_comments_path(:contest => @contest.permalink, :role => "admin", :contest_id => @contest_instance.permalink, :uuid => @contest_instance.uuid)	  
	else
	  flash.now[:alert] = "Error saving comment."
	  
      if @comment.errors.on(:body)
        flash.now[:alert] += " Comment cannot be empty and maximum 1000 characters allowed."
      end
      flash.delete(:notice)
      
      if @is_reply
        @reply = Comment.new
        @reply.body = @comment.body
        @comment = Comment.find(params[:parent_id])        
        render :show
      else
        render :new
      end
	end

  end
  
  def destroy
    @comment = Comment.find(params[:id])
    if @comment.destroy
      #render :json => @comment, :status => :ok
      flash[:notice] = "The comment was successfully deleted!"
    else
      #render :js => "alert('error deleting comment');"
      flash[:alert] = "Error deleting comment"
    end  
  end

protected
  def set_context_from_request_params
    set_contest_context(params[:contest], params[:role], params[:contest_id], params[:uuid])
  end
end
