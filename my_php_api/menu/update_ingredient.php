<?php
header("Content-Type: application/json");
error_reporting(E_ALL & ~E_NOTICE & ~E_WARNING);
include("../db.php");

$data = json_decode(file_get_contents("php://input"), true);
$ingredient_id = intval($data['ingredient_id'] ?? 0);
$quantity = floatval($data['quantity'] ?? 0);

if ($ingredient_id <= 0 || $quantity <= 0) {
    echo json_encode(["success" => false, "message" => "Ingredient ID or quantity missing"]);
    exit;
}

$stmt = $conn->prepare("UPDATE menu_ingredients SET quantity=? WHERE id=?");
$stmt->bind_param("di", $quantity, $ingredient_id);

if ($stmt->execute()) {
    echo json_encode(["success" => true, "message" => "Ingredient updated successfully"]);
} else {
    echo json_encode(["success" => false, "message" => $stmt->error]);
}

$stmt->close();
$conn->close();
