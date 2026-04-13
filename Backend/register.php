<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header('Content-Type: application/json');
error_reporting(E_ERROR | E_PARSE);

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

require_once 'db.php';
require_once 'response.php';

$email      = strtolower(trim($_POST['email']      ?? ''));
$password   = trim($_POST['password']   ?? '');
$first_name = trim($_POST['first_name'] ?? '');
$last_name  = trim($_POST['last_name']  ?? '');

if (empty($email) || empty($password) || empty($first_name) || empty($last_name)) {
    send_error("All fields are required");
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    send_error("Invalid email format");
}

if (strlen($password) < 6) {
    send_error("Password must be at least 6 characters");
}

$hashed = password_hash($password, PASSWORD_DEFAULT);

$stmt = $conn->prepare(
    "INSERT INTO users (email, password, first_name, last_name) VALUES (?, ?, ?, ?)"
);
$stmt->bind_param("ssss", $email, $hashed, $first_name, $last_name);

if ($stmt->execute()) {
    send_success([], "Account created successfully");
} else {
    // ✅ Detect duplicate email (MySQL error 1062 = duplicate entry)
    if ($conn->errno === 1062) {
        send_error("An account with this email already exists");
    }
    send_error("Failed to create account. Please try again.");
}

$stmt->close();
$conn->close();
?>
