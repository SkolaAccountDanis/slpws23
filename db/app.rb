# app.rb
require 'sinatra'
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
