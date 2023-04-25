require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'

enable :sessions

$db = SQLite3::Database.new("db/characters.db")
$db.results_as_hash = true

# class DbAccesor
# 
# This class contains all SQL code for interacting with the database file aswell as the Bcrypt code necessary for the login
class DbAccesor
    
    # Takes everything from the characters table
    # 
    # @return [Hash] containing all data
    def all_characters()
        $db.execute("SELECT * FROM characters")
    end

    # Takes all characters assigned to user_id
    # 
    # @param [Integer] user_id the user identification
    # @return [Hash] all data from all characters with user_id
    def specific_characters(user_id)
        $db.execute("SELECT * FROM characters WHERE users_id = ?", user_id )
    end

    # Takes character which is attributed with specific char_id
    # 
    # @param [Integer] char_id thecharacter identification
    # @return [Hash] all info from specific character
    def specific_character(char_id)
        $db.execute("SELECT * FROM characters WHERE id = ?", char_id).first
    end
    
    # Create a new character connected to a used with used_id
    # 
    # @param [String] name the name of the character
    # @param [String] race the race of the character
    # @param [String] char_class the class of the character
    # @param [Integer] level the characters level
    # @param [Integer] str the strength score of the character
    # @param [Integer] dex the dexterity score of the character
    # @param [Integer] con the constitution score of the character
    # @param [Integer] int the intelligence score of the character
    # @param [Integer] wis the wisdom score of the character
    # @param [Integer] cha the charisma score of the character
    # @param [Integer] user_id the user_id assigned to the character
    # @return [Hash] inserts character data into characters table 
    def create_character(name, race, char_class, level, str, dex, con, int, wis, cha, user_id)
        $db.execute("INSERT INTO characters (name, race, class, level, str, dex, con, int, wis, cha, users_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", name, race, char_class, level, str, dex, con, int, wis, cha, user_id)
    end

    # Edit an existing character, chancing values
    # 
    # @param [String] name the name of the character
    # @param [String] race the race of the character
    # @param [String] char_class the class of the character
    # @param [Integer] level the characters level
    # @param [Integer] str the strength score of the character
    # @param [Integer] dex the dexterity score of the character
    # @param [Integer] con the constitution score of the character
    # @param [Integer] int the intelligence score of the character
    # @param [Integer] wis the wisdom score of the character
    # @param [Integer] cha the charisma score of the character
    # @param [Integer] id the characters identification
    # @return [Hash] the updated values of the character
    def edit_character(name, race, char_class, level, str, dex, con, int, wis, cha, id)
        $db.execute("UPDATE characters SET name = ?, race = ?, class = ?, level = ?, str = ?, dex = ?, con = ?, int = ?, wis = ?, cha = ? WHERE id = ?", name, race, char_class, level, str, dex, con, int, wis, cha, id)
    end


    # Takes all items which are assigned to a specific character id
    # 
    # @param [Integer] char_id the character identification 
    # @return [Hash] returns everything from items table which is assigned to char_id
    def all_items(char_id)
        $db.execute("SELECT * FROM items WHERE character_id = ?", char_id) 
    end

    # Create new item connected with a character with specific char_id
    # 
    # @param [String] itemName the name of the item
    # @param [String] itemDescription the description of the item
    # @param [Integer] character_id the id to a specific character
    # @return [Hash] inserts data from params into the table items
    def create_items(itemName, itemDescription, character_id) 
        $db.execute("INSERT INTO items (name, description, character_id) VALUES (?, ?, ?)", itemName, itemDescription, character_id)
    end

    # Update item connected with specific id
    # 
    # @param [String] itemName the name of the item
    # @param [String] itemDescription the description of the item
    # @param [Integer] id the id to a specific item
    # @return [Hash] updates the values in the table with new values
    def edit_items(itemName, itemDescription, id)
        $db.execute("UPDATE items SET name = ?, description = ? WHERE id = ?",itemName, itemDescription, id)
    end

    # Delete character with specific character-id
    # 
    # @param [Integer] id the id of specific character
    # @return [Hash] delete the character and the items connected to it
    def delete_character(id) 
        $db.execute("DELETE FROM characters WHERE id = ?",id)
        $db.execute("DELETE FROM items WHERE character_id = ?", id)
    end
    
    # Delete specific item from specific character
    # 
    # @param [Integer] id the id of the character
    # @param [Integer] items_id  the id of the item
    # @return [Hash] delete everything from items that correspond to the correct item_id and character id
    def delete_items(id, items_id)
        $db.execute("SELECT * FROM items WHERE character_id = ?", id)
        $db.execute("DELETE FROM items WHERE id =?", items_id)
    end

    # Delete the user and everything that is connected to the user
    # 
    # @param [Integer] user_id the id of the user
    # @return [Hash] delete the user aswell as the characters and items connected with the user
    def delete_user(user_id)
        $db.execute("DELETE FROM users WHERE id=?", user_id)
        $db.execute("DELETE FROM characters WHERE id = ?", user_id)
        $db.execute("DELETE FROM items WHERE id = ?", user_id)
    end

    # Select a specific username
    # 
    # @param [Integer] user_id the id of the user
    # @return [Hash] returns the username connected with the user_id
    def username(user_id)
        $db.execute('SELECT username FROM users WHERE id = ?', user_id).first
    end

    # Select all users from the database users
    # 
    # @return [Hash] returns all the data in the table
    def all_users()
        $db.execute("SELECT * FROM users")
    end

    # Selects everything from user with specific username
    # 
    # @param [String] username the username of the user
    # @return [Hash] returns everything from the table with corresponding username
    def specific_user(username)
        return $db.execute('SELECT * FROM users WHERE username = ?', username).first
    end

    # A check used to verify if the character belongs to a user
    # 
    # @param [Integer] char_id the id of the character
    # @return [Hash] returns the user_id from the characters table which is connected with the character id
    def userCheck(char_id)
        return $db.execute("SELECT users_id FROM characters WHERE id = ?", char_id)
    end

    # Check if the password of the user put in matches with the database
    # 
    # @param [String] password the password put in by the user
    # @param [String] check_password the password going through the Bcrypt class
    # @param [Integer] user_id the id used to get the correct username
    # @return [String, Integer, nil, nil] returns the username and the user_id, if there is nothing there it returns nil
    def passwordCheck(password, check_password, user_id)
        if (BCrypt::Password.new(check_password) == password)
            username = DbAccesor.new.username(user_id)
            return username, user_id
          else
            return nil, nil
          end
    end

    # Checks if user has the value needed in permissions
    # 
    # @param [Integer] user_id the if of the user
    # @return [Hash] returns the key value pair: "permissions"
    def permissions(user_id)
        $db.execute("SELECT permissions from users WHERE id = ?", user_id).first
    end

    # Orders the likes table to ascending
    # 
    # @param [Integer] user_id the id of the user
    # @return [Hash] selects everything from the table likes depending on user_id
    def order_likes_table(user_id)
        $db.execute("SELECT * FROM likes WHERE user_id = ? ORDER BY char_id ASC", user_id)
    end

    # Connects the needed columns into a new table for the likes system to work
    # 
    # @return [Hash] returns a new table through JOIN with the neccesary columns in place
    def left_join_characters()
        $db.execute("WITH tmp(char_id, likes) AS (SELECT char_id,COUNT(*) FROM likes GROUP BY char_id)
            SELECT id,name,class,race,level,str,dex,con,int,wis,cha,users_id, COALESCE(tmp.likes,0) AS likes FROM characters
            LEFT JOIN tmp ON tmp.char_id = characters.id;") 
    end

    # Inserts into table likes the user id and character id
    # 
    # @param [Integer] user_id the id of the user
    # @param [Integer] charID the id of the character
    # @return [Hash] inserts the ids into the table
    def update_likes(user_id, charID)
        return $db.execute("INSERT INTO likes (user_id, char_id) VALUES (?, ?)",user_id, charID)
    end

    # Takes away a like from the table likes
    # 
    # @param [Integer] user_id the if of the user
    # @param [Integer] charID the id of the character
    # @return [Hash] deletes from the like table depending on the ids
    def delete_likes(user_id, charID)
        return $db.execute("DELETE FROM likes WHERE (user_id = ?) AND (char_id = ?)", user_id, charID)
    end
end

