<?php
header("Content-Type: application/json");
error_reporting(E_ALL & ~E_NOTICE & ~E_WARNING);
include("../db.php");

$data = json_decode(file_get_contents("php://input"), true);
$ingredient_id = intval($data['ingredient_id'] ?? 0);

if ($ingredient_id <= 0) {
    echo json_encode(["success" => false, "message" => "Ingredient ID missing"]);
    exit;
}

$stmt = $conn->prepare("DELETE FROM menu_ingredients WHERE id=?");
$stmt->bind_param("i", $ingredient_id);

if ($stmt->execute()) {
    echo json_encode(["success" => true, "message" => "Ingredient deleted successfully"]);
} else {
    echo json_encode(["success" => false, "message" => $stmt->error]);
}

$stmt->close();
$conn->close();
