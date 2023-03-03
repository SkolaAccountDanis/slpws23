# app.rb
require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative 'model'

enable :sessions



# Connect to the SQLite3 database
db = SQLite3::Database.new("db/characters.db")



# Define the routes for the app
get '/register' do
  slim :register
end

post '/users/new' do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]
  
  if (password == password_confirm)
    encoded_password = BCrypt::Password.create(password)
    db.execute("INSERT INTO users (username, password) VALUES (?, ?)", username, encoded_password)
    redirect("/login")
  else
    "Lösenorden matchar inte, försök igen!"
  end

end

get '/login' do
  slim :login
end

get "/index" do
  slim :index
end

post "/login/update" do
  username = params[:username]
  password = params[:password]
  db.results_as_hash = true
  result = db.execute('SELECT * FROM users WHERE username = ?', username).first
  check_password = result["password"].to_s
  user_id = result["id"]

  p check_password
  if (BCrypt::Password.new(check_password) == password)
    user_id = session[:id]

    redirect("/index")
  else
    "FEL LÖSENORD"
  end

end


get '/' do
  slim :homePage
end

get '/new' do
  slim :new
end


post '/create' do
  # Create a new character in the database
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
  redirect to('/')
end

get '/characters' do
  # Get all characters from the database
  user_id = session[:id]
  @characters = db.execute("SELECT * FROM characters WHERE users_id = ?", user_id )
  slim :characters
end


post '/characters/:id/delete' do
  DbAccesor.new.delete_character(id = params[:id].to_i) 
  redirect('/characters')
end

get '/characters/:id/edit' do
  # Get a specific character from the database using the id parameter
  @character = db.execute("SELECT * FROM characters WHERE id = ?", params[:id]).first
  slim :edit
end

post '/update/:id' do
  # Update a specific character in the database using the id parameter
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
  redirect to('/characters')
end

get '/characters/:id/play' do
  # Get a specific character from the database using the id parameter
  @character = db.execute("SELECT * FROM characters WHERE id = ?", params[:id]).first
  slim :play
end

get '/characters/:id/items' do 
  @character_id = params[:id].to_i

  db.results_as_hash = true
  @items = db.execute("SELECT * FROM items WHERE character_id = ?", @character_id) 
  if @items == nil
    @items = ['No items!']
  end
  slim :items
end



get "/characters/:id/items/new" do
  @result = params[:id]
  slim :new_items
end


post "/characters/:id/items/delete_items/:items_id" do
  DbAccesor.new.delete_items(@char_id = params[:id], @item = params[:items_id])
  redirect to("/characters/#{@char_id}/items")
end

post '/create_items/:char_id' do
  DbAccesor.new.create_items(
    itemName = params[:itemName],
    itemDescription = params[:itemDescription],
    @charIdForItems = params[:char_id]
  )

  redirect to("/characters/#{@charIdForItems}/items")
end

get "/characters/:id/items/edit_items/:item_id" do
  @charID = params[:id]
  @ItemId = params[:item_id]
  slim :edit_items
end

post "/edit_items/:item_id" do
  DbAccesor.new.edit_items(
    itemName = params[:itemName],
    itemDescription = params[:itemDescription],
    @edit_Items_charID = params[:item_id]
  )
  charID = params[:charID]
  redirect to("/characters/#{charID}/items")
end