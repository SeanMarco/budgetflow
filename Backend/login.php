<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
error_reporting(E_ERROR | E_PARSE);
header('Content-Type: application/json');

$conn = new mysqli("localhost", "root", "", "budgetflow");

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Database connection failed"]));
}

$email = $_POST['email'] ?? '';
$password = $_POST['password'] ?? '';

if (empty($email) || empty($password)) {
    echo json_encode(["status" => "error", "message" => "Email and password required"]);
    exit;
}

// Use prepared statement (IMPORTANT 🔥)
$stmt = $conn->prepare("SELECT id, email, password, first_name, last_name FROM users WHERE email = ?");
$stmt->bind_param("s", $email);
$stmt->execute();

$result = $stmt->get_result();

if ($result->num_rows == 0) {
    echo json_encode(["status" => "error", "message" => "User not found"]);
    exit;
}

$user = $result->fetch_assoc();

// Verify password
if (password_verify($password, $user['password'])) {
    echo json_encode([
        "status" => "success",
        "user" => [
            "id" => $user['id'],
            "email" => $user['email'],
            "first_name" => $user['first_name'],
            "last_name" => $user['last_name']
        ]
    ]);
} else {
    echo json_encode(["status" => "error", "message" => "Invalid password"]);
}

$stmt->close();
$conn->close();
?>
