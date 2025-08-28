## DB.gd
## SQLite-backed user database module for the MMORPG server.
## Features:
## - Creates the database and the "users" table on first run.
## - Inserts new accounts with default character slots (3 per user).
## - Validates passwords for login (plain-text as of now).
## - Retrieves stored character JSON for a username.
extends Node

## SQLite interface instance.
var SQL = SQLite.new()
## Database file path.
var path = "res://users.db"

## Schema definition for the "users" table.
## NOTE: Keep this in sync with any INSERT/SELECT queries below.
var table_definition = {
	"id": {"data_type": "int", "primary_key": true, "auto_increment": true},
	"name": {"data_type": "text", "unique": true, "not_null": true},
	"password": {"data_type": "text", "not_null": true},
	"email": {"data_type": "text", "unique": true, "not_null": true},
	"deletedata": {"data_type": "int", "not_null": true, "default": 0},
	"banned": {"data_type": "int", "not_null": true, "default": 0},
	"daystounban": {"data_type": "int", "not_null": true, "default": 0},
	"CharacterData": {"data_type": "text", "not_null": true},
	"gamename": {"data_type": "text", "not_null": true},
	"playerpos": {"data_type": "text", "not_null": true}
}

## Ensures the database exists when the node enters the tree.
func _ready() -> void:
	_create_database()


## Creates the database file and the "users" table if not present.
## Prints status messages indicating creation or existing DB.
func _create_database() -> void:
	SQL.path = path
	if not FileAccess.file_exists(path):
		if SQL.open_db():
			if SQL.create_table("users", table_definition):
				print_rich("[color=green]DB: [/color]Database created at %s" % path)
			SQL.close_db()
	else:
		print_rich("[color=yellow]DB: [/color]Database already exists")


## Creates a new user account.
## Arguments:
## - username (String): unique account name.
## - password (String): password (currently stored in plain text; consider hashing).
## - email (String): unique email address.
## - gamename (String): in-game display name.
## Returns:
## - bool: true if the account was created; false otherwise.
func create_account(username: String, password: String, email: String, gamename: String) -> bool:
	if SQL.open_db():
		# Default character data (3 slots). Adjust fields as your game evolves.
		var json_data = {
			"CharacterData": {
				"player": {"activo":0,"aspecto":{"color":0,"pelo":0},"clase":"","equipado":{"arma":"","armadura":"","casco":"","escudo":""},"inventario":[],"nivel":0,"personaje":""},			}
		}
		var json_text = JSON.stringify(json_data)

		# Use bound parameters to avoid SQL injection issues.
		var query = "INSERT INTO users (CharacterData, name, password, email, gamename) VALUES (?, ?, ?, ?, ?);"
		var ok = SQL.query_with_bindings(query, [json_text, username, password, email, gamename])
		SQL.close_db()

		if ok:
			print_rich("[color=green]DB: [/color]Account successfully created for %s" % username)
			return true
		else:
			print_rich("[color=red]DB ERROR: [/color]" + str(SQL.error_message))
	return false


## Checks whether the provided password matches the stored one for a username.
## Arguments:
## - username (String): account name.
## - taken_password (String): password received (already decrypted).
## Returns:
## - bool: true if passwords match, false otherwise.
func check_same_password(username: String, taken_password: String) -> bool:
	if SQL.open_db():
		var query = "SELECT password FROM users WHERE name = ?;"
		if SQL.query_with_bindings(query, [username]):
			var result = SQL.query_result
			SQL.close_db()
			if result.size() > 0:
				return str(result[0]["password"]) == taken_password
		SQL.close_db()
	return false


## Retrieves the JSON character data for a given username.
## Arguments:
## - username (String): account name.
## Returns:
## - String: JSON text with character data; "{}" if not found.
func get_characters_data(username: String) -> String:
	if SQL.open_db():
		var query = "SELECT CharacterData FROM users WHERE name = ?;"
		if SQL.query_with_bindings(query, [username]):
			var result = SQL.query_result
			if result.size() > 0:
				var json_data = result[0]["CharacterData"]
				SQL.close_db()
				return str(json_data)
		SQL.close_db()
	return "{}"
