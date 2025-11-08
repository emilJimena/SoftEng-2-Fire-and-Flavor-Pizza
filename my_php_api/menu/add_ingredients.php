<?php
header("Content-Type: application/json");
include("../db.php");

$menu_id = $_POST['menu_id'] ?? 0;
$ingredients = $_POST['ingredients'] ?? '[]'; // JSON string
$data = json_decode($ingredients, true);

if ($menu_id == 0 || !is_array($data)) {
    echo json_encode(["success" => false, "message" => "Invalid menu or ingredients"]);
    exit;
}

// remove existing first
$conn->query("DELETE FROM menu_ingredients WHERE menu_id = $menu_id");

$stmt = $conn->prepare("INSERT INTO menu_ingredients (menu_id, material_id, quantity) VALUES (?, ?, ?)");
foreach ($data as $ing) {
    $material_id = intval($ing["material_id"] ?? 0);
    $qty = floatval($ing["quantity"] ?? 0);
    if ($material_id > 0 && $qty > 0) {
        $stmt->bind_param("iid", $menu_id, $material_id, $qty);
        $stmt->execute();
    }
}
$stmt->close();

echo json_encode(["success" => true, "message" => "Ingredients saved"]);
$conn->close();
?>
