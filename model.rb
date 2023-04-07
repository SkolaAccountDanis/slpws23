require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'



class DbAccesor
    
    def create_character(name, race, char_class, level, str, dex, con, int, wis, cha, user_id)
        db = SQLite3::Database.new("db/characters.db")
        db.execute("INSERT INTO characters (name, race, class, level, str, dex, con, int, wis, cha, users_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", name, race, char_class, level, str, dex, con, int, wis, cha, user_id)
    end

    def edit_character(name, race, char_class, level, str, dex, con, int, wis, cha, id)
        db = SQLite3::Database.new("db/characters.db")
        db.execute("UPDATE characters SET name = ?, race = ?, class = ?, level = ?, str = ?, dex = ?, con = ?, int = ?, wis = ?, cha = ? WHERE id = ?", name, race, char_class, level, str, dex, con, int, wis, cha, id)
    end

    def create_items(itemName, itemDescription, character_id) 
        db = SQLite3::Database.new("db/characters.db")
        db.execute("INSERT INTO items (name, description, character_id) VALUES (?, ?, ?)", itemName, itemDescription, character_id)
    end

    def edit_items(itemName, itemDescription, id)
        db = SQLite3::Database.new("db/characters.db")
        db.execute("UPDATE items SET name = ?, description = ? WHERE id = ?",itemName, itemDescription, id)
    end

    def delete_character(id) 
        db = SQLite3::Database.new("db/characters.db")
        db.execute("DELETE FROM characters WHERE id = ?",id)
        db.execute("DELETE FROM items WHERE character_id = ?", id)
    end

    def delete_items(id, items_id)
        db = SQLite3::Database.new("db/characters.db")
        db.execute("SELECT * FROM items WHERE character_id = ?", id)
        db.execute("DELETE FROM items WHERE id =?", items_id)
    end

    def delete_user(user_id)
        db = SQLite3::Database.new("db/characters.db")
        db.execute("DELETE FROM users WHERE id=?", user_id)
        db.execute("DELETE FROM characters WHERE id = ?", user_id)
        db.execute("DELETE FROM items WHERE id = ?", user_id)
    end

    def userCheck(char_id)
        db = SQLite3::Database.new("db/characters.db")
        return db.execute("SELECT users_id FROM characters WHERE id = ?", char_id)
    end

end

