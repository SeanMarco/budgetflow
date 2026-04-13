<?php

function send_success($data = [], $message = "Success") {
    echo json_encode([
        "status" => "success",
        "message" => $message,
        "data" => $data
    ]);
    exit;
}

function send_error($message = "Error") {
    echo json_encode([
        "status" => "error",
        "message" => $message
    ]);
    exit;
}
