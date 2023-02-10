# app.rb
require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'

# Connect to the SQLite3 database
db = SQLite3::Database.new("db/characters.db")

# Define the routes for the app
get '/' do
  slim :index
end

get '/new' do
  slim :new
end


post '/create' do
  # Create a new character in the database
  name = params[:name]
  race = params[:race]
  char_class = params[:class]
  str = params[:str]
  dex = params[:dex]
  con = params[:con]
  int = params[:int]
  wis = params[:wis]
  cha = params[:cha]

  db.execute("INSERT INTO characters (name, race, class, str, dex, con, int, wis, cha) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)", name, race, char_class, str, dex, con, int, wis, cha)
  redirect to('/')
end

get '/characters' do
  # Get all characters from the database
  @characters = db.execute("SELECT * FROM characters")
  slim :characters
end


post('/characters/:id/delete') do
  id = params[:id].to_i
  db.execute("DELETE FROM characters WHERE id = ?",id)
  db.execute("DELETE FROM items WHERE character_id = ?", id)
  redirect('/characters')
end

get '/edit/:id' do
  # Get a specific character from the database using the id parameter
  @character = db.execute("SELECT * FROM characters WHERE id = ?", params[:id]).first
  slim :edit
end

post '/update/:id' do
  # Update a specific character in the database using the id parameter
  name = params[:name]
  race = params[:race]
  char_class = params[:class]
  level = params[:level]
  str = params[:str]
  dex = params[:dex]
  con = params[:con]
  int = params[:int]
  wis = params[:wis]
  cha = params[:cha] 
  
  db.execute("UPDATE characters SET name = ?, class = ?, race = ?, level = ?, str = ?, dex = ?, con = ?, int = ?, wis = ?, cha = ? WHERE id = ?", name, char_class, race, level, str, dex, con, int, wis, cha, params[:id])
  redirect to('/characters')
end

get '/play/:id' do
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
  p @items
  slim :items
end

get "/characters/:id/items/create_items" do
  @result = params[:id]
  slim :new_items
end

post '/create_items/:id' do
  @charIdForItems = params[:id]
  itemName = params[:itemName]
  itemDescription = params[:itemDescription]
  db.execute("INSERT INTO items (name, description, character_id) VALUES (?, ?, ?)", itemName, itemDescription, @charIdForItems)

  redirect to("/characters/#{@charIdForItems}/items")
end

get "/characters/:id/items/edit_items/:item_id" do
  @charID = params[:id]
  @ItemId = params[:item_id]
  slim :edit_items
end

post "/edit_items/:item_id" do
  @edit_Items_charID = params[:item_id]
  itemName = params[:itemName]
  itemDescription = params[:itemDescription]
  charID = params[:charID]
  db.execute("UPDATE items SET name = ?, description = ? WHERE id = ?",itemName, itemDescription, @edit_Items_charID)
  redirect to("/characters/#{charID}/items")
end