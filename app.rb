# app.rb
require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative 'model'


enable :sessions


# This method checks if the user is authorized to access the requested and redirects if they arent
# 
# @param [Array] restricted_paths An array with the names of the restriced routes
# @param [Integer] user_id The id of the user
# @return [void]
before do
  restricted_paths = ['/characters/','/characters/*', '/adminSite/','/adminSite/*', '/mainsite', '/shareChar/', '/shareChar/*']
  user_id = session[:id]
  @permission = DbAccesor.new.permissions(user_id)

  if session[:id] == nil && restricted_paths.include?(request.path_info)   
    redirect '/'
  end
 
  if session[:logged_in] && @permission["permissions"] != 1 && request.path_info == '/adminSite'
    redirect '/'
  end
end


# Display the register form
# 
# @return [String] the render of the registration form
get '/register/' do
  slim :register
end

# Registers a new user with the provided username and password
# 
# @option [String] :username the username of the user
# @option [String] :password the password of the user
# @option [String] :password_confirm the password of the user repeated
# @return [void]
post '/users/new' do
  username = params[:username] 
  password = params[:password]
  password_confirm = params[:password_confirm]
  
  if (password == password_confirm)
    encoded_password = BCrypt::Password.create(password)
    db.execute("INSERT INTO users (username, password) VALUES (?, ?)", username, encoded_password)
    redirect("/login/")
  else
    p "Lösenorden matchar inte, försök igen!"
    redirect("/register/")
  end
end

# Display the login form
# 
# @return [String] the render of the login form
get '/login/' do
  slim :login
end

# Displays the main site
# 
# @return [void]
get "/mainsite" do
  user_id = session[:id]
  @permission = DbAccesor.new.permissions(user_id)
  @username = DbAccesor.new.username(user_id)
  slim :mainsite
end

# Authenticates a user with username and password and updates their session if succesfull
# 
# @option [String] :username the username of the user
# @option [String] :password the password of the user
# @return [void]
post "/login/update" do
  if session[:time] == nil
    session[:time] = Time.new()
  elsif Time.new() - session[:time] < 10
    redirect to("/mainsite")
  end
  @username = params[:username]
  password = params[:password]
  @result = DbAccesor.new.specific_user(@username)
  p @result
  check_password = @result["password"]
  user_id = @result["id"]
  
  username, user_id = DbAccesor.new.passwordCheck(password, check_password, user_id)
  if username == nil
    session[:time] = Time.new()
    redirect to("/")
  end
  session[:id] = user_id 
  session[:username] = username

  redirect to("/mainsite")
end

# Displays the home page
# 
# @return [void]
get '/' do
  slim :homePage
end

# Displays the create characters site
# 
# @return [void]
get '/characters/new' do
  # redirect("/") unless session[:id]
  slim (:"characters/new")
end

# Create a new character in the database
# 
# @option [String] :name The name of the character
# @option [String] :race The race of the character
# @option [String] :class The characters class
# @option [Integer] :level The characters level
# @option [Integer] :str The strength of the character
# @option [Integer] :dex The dexterity of the character
# @option [Integer] :con The constitution of the character
# @option [Integer] :int The intelligence of the character
# @option [Integer] :wis The wisdom of the character
# @option [Integer] :cha The charisma of the character
# @option [Integer] :user_id The id of the user creating the character
# 
# @return [void]
post '/characters' do
  DbAccesor.new.create_character(
    name = params[:name],
    race = params[:race],
    char_class = params[:class],
    level = params[:level],
    str = params[:str],
    dex = params[:dex],
    con = params[:con],
    int = params[:int],
    wis = params[:wis],
    cha = params[:cha],
    user_id = session[:id]
  )
  redirect to('/mainsite')
end

# Get all characters associated with the current user or get all characters if user is an admin
# 
# @return [void]
get '/characters/' do
  user_id = session[:id]
  @permissions = DbAccesor.new.permissions(user_id)
  
  if @permissions["permissions"] == 1
    @characters = DbAccesor.new.all_characters()
  else
    @characters = DbAccesor.new.specific_characters(user_id)
  end
  slim (:"characters/index")
end

# Display the site exclusive to the admin while rendering all users
# 
# @return [void]
get '/adminSite/' do
  @all_users = DbAccesor.new.all_users()
  slim :adminSite
end

# Delete the user with specified id from database
# 
# @option user_id [Integer] the id of the user to delete
# @return [void]
post "/adminSite/:id/delete" do
  user_id = params[:id]
  DbAccesor.new.delete_user(user_id)
  redirect('/adminSite/')
end

# Deletes a character from the database by ID. If the current user has admin permissions, the character will be deleted
# regardless of who owns it. Otherwise, only the owner of the character can delete it.
#
# @option [Integer] :id The ID of the character to be deleted.
# @return [void]
post '/characters/:id/delete' do
  permissions = DbAccesor.new.permissions(session[:id])
  if permissions["permissions"] == 1
    DbAccesor.new.delete_character(id = params[:id].to_i)
  else
    charOwnerId = DbAccesor.new.userCheck(params[:id]).first
    redirect("/") unless charOwnerId[0] == session[:id] 
    DbAccesor.new.delete_character(params[:id].to_i) 
  end
  redirect('/characters/')
end
 
# Renders the character edit page for a specific character ID.
#
# @return [void] 
get '/characters/:id/edit' do
  permissions = DbAccesor.new.permissions(session[:id])
  if permissions["permissions"] == 1
    @username = DbAccesor.new.username(session[:id])
    @character = DbAccesor.new.specific_character(params[:id])
  else
    charOwnerId = DbAccesor.new.userCheck(params[:id]).first
    redirect("/") unless charOwnerId[0] == session[:id] 
    @username = DbAccesor.new.username(session[:id])
    @character = DbAccesor.new.specific_character(params[:id])
  end
  slim (:"characters/edit")
end

# Edits an existing character from the database
# 
# @option [String] :name The name of the character
# @option [String] :race The race of the character
# @option [String] :class The characters class
# @option [Integer] :level The characters level
# @option [Integer] :str The strength of the character
# @option [Integer] :dex The dexterity of the character
# @option [Integer] :con The constitution of the character
# @option [Integer] :int The intelligence of the character
# @option [Integer] :wis The wisdom of the character
# @option [Integer] :cha The charisma of the character
# @option [Integer] :user_id The id of the user creating the character
# 
# @return [void]
post '/characters/:id/update' do
  permissions = DbAccesor.new.permissions(user_id)
  if permissions["permissions"] == 1  
    DbAccesor.new.edit_character( 
      name = params[:name],
      race = params[:race],
      char_class = params[:class],
      level = params[:level],
      str = params[:str],
      dex = params[:dex],
      con = params[:con],
      int = params[:int],
      wis = params[:wis],
      cha = params[:cha], 
      params[:id])
    else
      charOwnerId = DbAccesor.new.userCheck(params[:id]).first
      redirect("/") unless charOwnerId[0] == session[:id]
      DbAccesor.new.edit_character( 
        name = params[:name],
        race = params[:race],
        char_class = params[:class],
        level = params[:level],
        str = params[:str],
        dex = params[:dex],
        con = params[:con],
        int = params[:int],
        wis = params[:wis],
        cha = params[:cha], 
        params[:id])
      end
  redirect to('/characters/')
end

# Displays the details of a specific character with the given ID.
# If the user has sufficient permissions, they can view any character.
# Otherwise, they can only view characters that they own.
# 
# @option [Integer] :id the ID of the character to be displayed
# @return [void]
get '/characters/:id' do
  permissions = DbAccesor.new.permissions(user_id)
  if permissions["permissions"] == 1
    @username = DbAccesor.new.username(session[:id])
    @character = DbAccesor.new.specific_character(params[:id])
  else
    charOwnerId = DbAccesor.new.userCheck(params[:id]).first
    redirect("/") unless charOwnerId[0] == session[:id]
    @username = DbAccesor.new.username(session[:id])
    @character = DbAccesor.new.specific_character(params[:id])
  end
  slim (:"characters/show")
end

# Display all items belonging to specific character
# 
# @return [void]
get '/characters/:id/items' do 
  permissions = DbAccesor.new.permissions(user_id)
  if permissions["permissions"] == 1
    @character_id = params[:id].to_i
    @items = DbAccesor.new.all_items(@character_id)
    if @items == nil
      @items = ['No items!']
    end
  else
    charOwnerId = DbAccesor.new.userCheck(params[:id]).first
    redirect("/") unless charOwnerId[0] == session[:id]
    @character_id = params[:id].to_i
    db.results_as_hash = true
    @items = db.execute("SELECT * FROM items WHERE character_id = ?", @character_id) 
    if @items == nil
      @items = ['No items!']
    end
  end
  slim (:"items/index")
end

# Render the form to create a new item for a character.
# @option [Integer] :id The id of the character to create a new item for
# 
# @return [void]
get "/characters/:id/items/new" do
  permissions = DbAccesor.new.permissions(session[:id])
  if permissions["permissions"] == 1
    @result = params[:id]
  else
    charOwnerId = DbAccesor.new.userCheck(params[:id]).first
    redirect("/") unless charOwnerId[0] == session[:id]
    @result = params[:id]
  end
  slim (:"items/new")
end

# Delete item connected with specific character
#
# @option [Integer] :id the character's id
# @option [Integer] :items_id the id of the item to delete
post "/characters/:id/items/:items_id/delete" do
  DbAccesor.new.delete_items(@char_id = params[:id], @item = params[:items_id])
  redirect to("/characters/#{@char_id}/items")
end

# Create item for specific character
# 
# @option [Integer] :char_id The ID of the character to create the item for.
# @option [String] :itemName The name of the item.
# @option [String] :itemDescription The description of the item.

# @return [void]
post '/create_items/:char_id' do
  DbAccesor.new.create_items(
    itemName = params[:itemName],
    itemDescription = params[:itemDescription],
    @charIdForItems = params[:char_id]
  )
  redirect to("/characters/#{@charIdForItems}/items")
end

# Display the edit item file
#
# @option [Integer] :id the character ID
# @option [Integer] :item_id the item ID to edit

# @return [void]
get "/characters/:id/items/:item_id/edit" do
  @charID = params[:id]
  @ItemId = params[:item_id]
  slim (:"items/edit")
end

# Updates an item's name and description
#
# @option [String] :itemName The new name for the item
# @option [String] :itemDescription The new description for the item
# @option [Integer] :item_id The ID of the item to be updated
#
# @return [void]
post "/edit_items/:item_id" do
  DbAccesor.new.edit_items(
    itemName = params[:itemName],
    itemDescription = params[:itemDescription],
    @edit_Items_charID = params[:item_id]
  )
  charID = params[:charID]
  redirect to("/characters/#{charID}/items")
end

# Clears the session and renders the home page.
# 
# @return [void]
get "/destroy" do
  session.clear
  slim :homePage
end

# Displays all characters and users to be shared with
#
# @return [void]
get '/shareChar/' do
  @all_characters = DbAccesor.new.left_join_characters()
  @all_users = DbAccesor.new.all_users()
  
  @relation = DbAccesor.new.order_likes_table(session[:id])
   
  @likes = []

  for character in @all_characters
      i = 0
      for relation in @relation
          if character["id"] == relation["char_id"]
              @likes.append(true)
              i += 1
          end
      end
      if i == 0
          @likes.append(false)
      end
  end 
  slim (:"characters/shareChar")
end

# Updates a like for shared character
#
# @option [Integer] :id the id of the shared character to be liked
# @return [void]
post '/shareChar/:id/update' do
  charID = params[:id]
  user_id = session[:id]

  DbAccesor.new.update_likes(user_id,charID)

  redirect to("/shareChar/")
end

# Deletes the likes of a shared character for the current user
# 
# @option [Integer] :id the ID of the character being shared
# @return [void]
post '/shareChar/:id/delete' do
  user_id = session[:id]
  charID = params[:id]
  
  DbAccesor.new.delete_likes(user_id, charID)

  redirect to("/shareChar/")
end

