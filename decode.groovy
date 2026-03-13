import java.nio.file.Files
import java.nio.file.Paths
import java.util.Base64

// Read the Base64-encoded content from a file
def filePath = "gen/system-imports.txt"  // Change to your actual file path
def base64String = new String(Files.readAllBytes(Paths.get(filePath))).trim()

// Decode the Base64 string
byte[] decodedBytes = Base64.decoder.decode(base64String)
def decodedString = new String(decodedBytes, "UTF-8")

// Print the decoded output
println "Decoded content:\n$decodedString"