<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
error_reporting(E_ALL);
ini_set('display_errors', 0);
header('Content-Type: application/json');

$conn = new mysqli('localhost', 'root', '', 'budgetflow');

if ($conn->connect_error) {
    echo json_encode(['status' => 'error', 'message' => 'Database connection failed']);
    exit;
}

// Get inputs
$email = $_POST['email'] ?? '';
$password = $_POST['password'] ?? '';
$first_name = $_POST['first_name'] ?? '';
$last_name = $_POST['last_name'] ?? '';

// Validate
if (empty($email) || empty($password) || empty($first_name) || empty($last_name)) {
    echo json_encode(['status' => 'error', 'message' => 'All fields are required']);
    exit;
}

// Hash password
$hashPassword = password_hash($password, PASSWORD_DEFAULT);

// Insert
$stmt = $conn->prepare("INSERT INTO users (email, password, first_name, last_name) VALUES (?, ?, ?, ?)");
$stmt->bind_param("ssss", $email, $hashPassword, $first_name, $last_name);

if ($stmt->execute()) {
    echo json_encode(['status' => 'success', 'message' => 'Account created successfully']);
} else {
    echo json_encode(['status' => 'error', 'message' => 'Failed to create account']);
}

$stmt->close();
$conn->close();
?>
