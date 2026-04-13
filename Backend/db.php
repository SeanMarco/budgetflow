<?php
// db.php — reusable database connection
// Include this in every endpoint: require_once 'db.php';

$conn = new mysqli("localhost", "root", "", "budgetflow");

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Database connection failed"]);
    exit;
}
?>
