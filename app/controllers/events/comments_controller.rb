class Events::CommentsController < ApplicationController
  include ThemeModule
  before_filter :authenticate_user!
  def create
    @event = Event.find(params[:event_id])
    @comment = Comment.build_from(@event, current_user.id, params[:body])
    if @comment.save
      redirect_to event_path(@event.friendly_id), :notice => "Your comment has been posted."
    else
      render_event_view_with_theme
    end
  end

  def reply
    @event = Event.find(params[:event_id])
    parent_comment = Comment.find(params[:id])
    @comment = Comment.build_from(@event, current_user.id, params[:body])
    if @comment.save
      @comment.move_to_child_of(parent_comment)
      redirect_to event_path(@event.friendly_id), :notice => "Your reply has been posted."
    else
      render_event_view_with_theme
    end
  end

private
  def render_event_view_with_theme
    theme = @event.get_together.theme.name
    render :template => "events/show", :layout => layout_path(theme)
  end

end
