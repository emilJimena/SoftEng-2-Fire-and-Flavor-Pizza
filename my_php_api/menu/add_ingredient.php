<?php
header("Content-Type: application/json");
error_reporting(E_ALL & ~E_NOTICE & ~E_WARNING);
include("../db.php");

$data = json_decode(file_get_contents("php://input"), true);
$menu_id = intval($data['menu_id'] ?? 0);
$material_id = intval($data['material_id'] ?? 0);
$quantity = floatval($data['quantity'] ?? 0);

if ($menu_id <= 0 || $material_id <= 0 || $quantity <= 0) {
    echo json_encode(["success" => false, "message" => "Invalid menu, material, or quantity"]);
    exit;
}

// Check duplicate
$stmt = $conn->prepare("SELECT id FROM menu_ingredients WHERE menu_id=? AND material_id=?");
$stmt->bind_param("ii", $menu_id, $material_id);
$stmt->execute();
$stmt->store_result();

if ($stmt->num_rows > 0) {
    echo json_encode(["success" => false, "message" => "Ingredient already exists"]);
    exit;
}
$stmt->close();

// Insert ingredient
$stmt = $conn->prepare("INSERT INTO menu_ingredients (menu_id, material_id, quantity) VALUES (?, ?, ?)");
$stmt->bind_param("iid", $menu_id, $material_id, $quantity);

if ($stmt->execute()) {
    echo json_encode(["success" => true, "message" => "Ingredient added successfully"]);
} else {
    echo json_encode(["success" => false, "message" => $stmt->error]);
}

$stmt->close();
$conn->close();
