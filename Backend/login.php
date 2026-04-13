<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header('Content-Type: application/json');
error_reporting(E_ERROR | E_PARSE);

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

require_once 'db.php';
require_once 'response.php';

$email    = strtolower(trim($_POST['email'] ?? ''));
$password = trim($_POST['password'] ?? '');

if (empty($email) || empty($password)) {
    send_error("Email and password are required");
}

// Check user
$stmt = $conn->prepare(
    "SELECT id, email, password, first_name, last_name FROM users WHERE email = ?"
);
$stmt->bind_param("s", $email);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    send_error("Invalid email or password");
}

$user = $result->fetch_assoc();
$stmt->close();

// Verify password
if (!password_verify($password, $user['password'])) {
    send_error("Invalid email or password");
}

// ✅ Update last login
$update = $conn->prepare("UPDATE users SET last_login = NOW() WHERE id = ?");
$update->bind_param("i", $user['id']);
$update->execute();
$update->close();

// ✅ Generate token
$token = bin2hex(random_bytes(32));

// ✅ RETURN CORRECT STRUCTURE
send_success([
    "id"         => $user['id'],
    "email"      => $user['email'],
    "first_name" => $user['first_name'],
    "last_name"  => $user['last_name'],
    "token"      => $token
], "Login successful");

$conn->close();
?>
