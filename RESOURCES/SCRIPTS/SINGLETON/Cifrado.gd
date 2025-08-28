## AES_Manager.gd
## AES encryption and decryption utility.
## Features:
## - AES CBC mode with PKCS7 padding.
## - Allows setting a custom key and IV at runtime or from a secure file.
## - Provides helper functions for Base64 encoding/decoding (useful in networking).
extends Node

## AES key (must be 16, 24, or 32 bytes long depending on AES variant).
var AES_KEY: PackedByteArray
## AES initialization vector (must be 16 bytes long).
var AES_IV: PackedByteArray


## Sets AES key and IV.
## Arguments can be either String or PackedByteArray.
## - key: AES key string or byte array.
## - iv: Initialization vector string or byte array.
func set_key_iv(key, iv) -> void:
	if typeof(key) == TYPE_STRING:
		AES_KEY = key.to_utf8_buffer()
	elif typeof(key) == TYPE_PACKED_BYTE_ARRAY:
		AES_KEY = key.duplicate()

	if typeof(iv) == TYPE_STRING:
		AES_IV = iv.to_utf8_buffer()
	elif typeof(iv) == TYPE_PACKED_BYTE_ARRAY:
		AES_IV = iv.duplicate()


## Encrypts text using AES in CBC mode with PKCS7 padding.
## Arguments:
## - text (String): Plain text to encrypt.
## Returns:
## - PackedByteArray: Encrypted data.
func aes_encrypt(text: String) -> PackedByteArray:
	if AES_KEY.is_empty() or AES_IV.is_empty():
		push_error("AES Server: Key or IV not defined")
		return PackedByteArray()

	var aes := AESContext.new()
	if aes.start(AESContext.MODE_CBC_ENCRYPT, AES_KEY, AES_IV) != OK:
		push_error("AES Server: Failed to start AES encryption")
		return PackedByteArray()

	var data := text.to_utf8_buffer()
	# PKCS7 padding
	var pad := 16 - (data.size() % 16)
	var pad_bytes := PackedByteArray()
	for i in range(pad):
		pad_bytes.append(pad)
	data.append_array(pad_bytes)

	var encrypted := aes.update(data)
	aes.finish()

	return encrypted


## Decrypts AES-encrypted data with PKCS7 unpadding.
## Arguments:
## - data (PackedByteArray): Encrypted byte array.
## Returns:
## - String: Decrypted plain text, or empty string on failure.
func aes_decrypt(data: PackedByteArray) -> String:
	if AES_KEY.is_empty() or AES_IV.is_empty():
		push_error("AES Server: Key or IV not defined")
		return ""

	var aes := AESContext.new()
	if aes.start(AESContext.MODE_CBC_DECRYPT, AES_KEY, AES_IV) != OK:
		push_error("AES Server: Failed to start AES decryption")
		return ""

	var decrypted := aes.update(data)
	aes.finish()

	if decrypted.is_empty():
		return ""

	# PKCS7 unpadding
	var pad := int(decrypted[-1])
	if pad > 0 and pad <= 16 and pad <= decrypted.size():
		decrypted = decrypted.slice(0, decrypted.size() - pad)

	return decrypted.get_string_from_utf8()


## Encrypts text and returns Base64 string (useful for network transmission).
## Arguments:
## - text (String): Plain text to encrypt.
## Returns:
## - String: Base64 encoded ciphertext.
func encrypt_base64(text: String) -> String:
	var enc := aes_encrypt(text)
	if enc.is_empty():
		return ""
	return Marshalls.raw_to_base64(enc)


## Decrypts a Base64 encoded AES ciphertext.
## Arguments:
## - b64 (String): Base64 encoded ciphertext.
## Returns:
## - String: Decrypted plain text.
func decrypt_base64(b64: String) -> String:
	if b64.is_empty():
		return ""
	var raw := Marshalls.base64_to_raw(b64)
	return aes_decrypt(raw)
