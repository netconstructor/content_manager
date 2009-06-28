class <%= controller_class_name %>Controller < ApplicationController
  # GET /<%= controller_file_path %>
  # GET /<%= controller_file_path %>.xml
  def index
    @<%= table_name %> = <%= controller_class_name %>.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @<%= table_name %> }
    end
  end

  # GET /<%= controller_file_path %>/1
  # GET /<%= controller_file_path %>/1.xml
  def show
    @<%= file_name %> = <%= controller_class_name %>.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @<%= file_name %> }
    end
  end

  # GET /<%= controller_file_path %>/new
  # GET /<%= controller_file_path %>/new.xml
  def new
    @<%= file_name %> = <%= controller_class_name %>.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @<%= file_name %> }
    end
  end

  # GET /<%= controller_file_path %>/1/edit
  def edit
    @<%= file_name %> = <%= controller_class_name %>.find(params[:id])
  end

  # POST /<%= controller_file_path %>
  # POST /<%= controller_file_path %>.xml
  def create
    @<%= file_name %> = <%= controller_class_name %>.new(params[:content_<%= file_name %>])

    respond_to do |format|
      if @<%= file_name %>.save
        flash[:notice] = '<%= class_name %> was successfully created.'
        format.html { redirect_to(content_<%= table_name %>_url) }
        format.xml  { render :xml => @<%= file_name %>, :status => :created, :location => @<%= file_name %> }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @<%= file_name %>.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /<%= controller_file_path %>/1
  # PUT /<%= controller_file_path %>/1.xml
  def update
    @<%= file_name %> = <%= controller_class_name %>.find(params[:id])

    respond_to do |format|
      if @<%= file_name %>.update_attributes(params[:content_<%= file_name %>])
        flash[:notice] = '<%= class_name %> was successfully updated.'
        format.html { redirect_to(content_<%= table_name %>_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @<%= file_name %>.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /<%= controller_file_path %>/1
  # DELETE /<%= controller_file_path %>/1.xml
  def destroy
    @<%= file_name %> = <%= controller_class_name %>.find(params[:id])
    @<%= file_name %>.destroy

    respond_to do |format|
      format.html { redirect_to(content_<%= table_name %>_url) }
      format.xml  { head :ok }
    end
  end
end
