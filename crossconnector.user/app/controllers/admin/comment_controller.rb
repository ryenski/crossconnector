class Admin::CommentController < ApplicationController
  
  before_filter :login_required, :except => [:new, :set_cookies]
  
  def open_comment_form
    # State = "new" or "edit"
    @comment = params[:state] == "edit" ? Comment.find(params[:id]) : Comment.new
    @comment.message_id = params[:message_id] if params[:message_id]
    render :partial => "admin/comment/#{params[:state]}_comment", :layout => false, :object => @comment
  end
  
  def delete
    @comment = Comment.find(params[:id])    
    if request.xhr? 
      @comment.destroy
      render :nothing => true, :layout => false
    elsif request.post?
      @comment.destroy
      flash[:notice] = "Comment deleted"
      redirect_to :action => "index"
    else
      flash[:notice] = "Comment not deleted"
      render :action => "delete_confirmation"
    end
  end
  
  def new
    
    
    if request.xhr? or request.post?
      begin
        @comment = Comment.new(params[:comment].merge(:ip => request.remote_ip, :user_agent => request.user_agent, :referer => request.referer))
        raise "This comment seems like spam. If it's not spam, please try again." if check_comment_for_spam(@comment)
        @comment.save or raise "<ul>#{@comment.errors.full_messages.collect{|e| "<li>#{e}</li>"}}</ul>"
        set_cookies(params[:comment])
        render :partial => "comment_list_item", :object => @comment, :layout => false
      rescue Exception => e
        render :text => "<div class=\"flash bad\"><strong>Sorry, your comment was not saved.</strong> <small>#{e}</small></div>", :layout => false
      end
    else
      redirect_to "/"
    end
  end
  
  def set_cookies(cookie)
    cookies[:comment_name] = cookie[:name]
    cookies[:comment_url] = cookie[:url]
    cookies[:comment_email] = cookie[:email]
  end
  
  
  def edit
    @comment = Comment.find(params[:comment][:id])
    if request.xhr? or request.post?
      @comment.update_attributes(params[:comment])
      render :partial => "comment_list_item", :object => @comment, :layout => false
    end
  end
    
  protected
  
  def check_comment_for_spam(comment)
    
    # The phone field is designed to trick spammers
    return true if !comment.phone.blank?
    
    @akismet = Akismet.new('your-key', 'http://your-blog.com') 

    return true unless @akismet.verifyAPIKey
    
    return @akismet.commentCheck(
              comment.ip,                   # remote IP
              comment.user_agent,           # user agent
              comment.referer,              # http referer
              comment.message_permalink,    # permalink
              'comment',                    # comment type
              comment.name,                 # author name
              comment.email,                # author email
              comment.url,                  # author url
              comment.body,                 # comment text
              {})                           # other
  end
  
end
