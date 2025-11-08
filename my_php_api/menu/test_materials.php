<?php
header('Content-Type: application/json');

// Simulate a quick response with sample data
$data = [
    ["id" => 1, "name" => "Cheese"],
    ["id" => 2, "name" => "Flour"],
    ["id" => 3, "name" => "Onion"],
    ["id" => 4, "name" => "Salt"],
    ["id" => 5, "name" => "Sugar"],
];

echo json_encode([
    "success" => true,
    "data" => $data
]);
exit;
