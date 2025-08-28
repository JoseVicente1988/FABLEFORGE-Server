## Server.gd
## Multiplayer server implementation for authentication and player data handling.
## Features:
## - Creates and manages server instance.
## - Handles user authentication (AES-256 encrypted passwords).
## - Stores connected clients in `Connection.ClientsData`.
## - Communicates securely with clients via RPC.
extends Control

## Reference to the Connection singleton (server manager).
var server = Connection
## ConfigFile for loading encrypted AES keys.
var FileData = ConfigFile.new()
## State to track if a user exists (not used yet).
var user_exists := false


## Called when the node is added to the scene tree.
func _ready() -> void:
	DB._create_database()
	server._create_server()
	_take_data()


## Debug function: prints current connected clients periodically.
func _on_timer_timeout() -> void:
	print(str(server.ClientsData))


## RPC: Handles login requests from clients.
## Arguments:
## - data: Dictionary with Base64 encoded username and encrypted password.
@rpc("any_peer")
func sendDataplayer(data: Dictionary) -> void:
	if not multiplayer.is_server():
		return

	var decoded_username = Marshalls.base64_to_utf8(data["user"])
	var encrypted_password = Marshalls.base64_to_raw(data["password"])
	var resolve_password = Cifrado.aes_decrypt(encrypted_password)
	var sender_id = multiplayer.get_remote_sender_id()

	# Validate credentials
	if DB.check_same_password(decoded_username, resolve_password):
		# Remove duplicate sessions for this user or ID
		for i in range(Connection.ClientsData.size() - 1, -1, -1):
			var client_data = Connection.ClientsData[i]
			if client_data["user"] == decoded_username or client_data["id"] == sender_id:
				Connection.ClientsData.remove_at(i)

		# Store authenticated client
		Connection.ClientsData.append({
			"user": decoded_username,
			"password": resolve_password,
			"id": sender_id
		})

		print_rich("[color=green]LOGIN: [/color] User %s successfully connected." % decoded_username)

		# Retrieve character data from DB
		var dataplayers = DB.get_characters_data(data["user"])
		if dataplayers == null:
			rpc_id(data["id"], "accept", true, {})
		else:
			rpc_id(data["id"], "accept", true, dataplayers)

	else:
		print_rich("[color=red]LOGIN ERROR: [/color] Invalid password for user %s" % decoded_username)
		rpc_id(data["id"], "accept", false)


## RPC: Placeholder callback for client confirmation after login.
## Arguments:
## - val: Boolean indicating success or failure.
## - dataplayers: Player data if login succeeded.
@rpc("any_peer")
func accept(val: bool, dataplayers: String) -> void:
	pass


## Loads AES key and IV from an encrypted config file.
## The config file must contain:
## [KEYS]
## AES_KEY=<your-key>
## AES_IV=<your-iv>
func _take_data() -> void:
	var encrypt = Marshalls.utf8_to_base64("esp_tre_05062025_nonedata")
	var err = FileData.load_encrypted_pass("res://data", encrypt)
	if err != OK:
		printerr("Error loading encrypted file")
		return

	var key_str = FileData.get_value("KEYS", "AES_KEY", "")
	var iv_str = FileData.get_value("KEYS", "AES_IV", "")

	if key_str.is_empty() or iv_str.is_empty():
		printerr("AES keys not found in config file")
		return

	# Convert to PackedByteArray and set in Cifrado
	Cifrado.set_key_iv(key_str, iv_str)

	print_rich("[color=yellow]AES Extract: [/color] AES Key: %s" % key_str)
	print_rich("[color=yellow]AES Extract: [/color] AES IV: %s" % iv_str)
