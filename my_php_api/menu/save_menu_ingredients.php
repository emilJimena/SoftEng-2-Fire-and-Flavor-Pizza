<?php
header('Content-Type: application/json');

$host = "localhost";
$user = "root";
$pass = "";
$db   = "testdb";

$conn = new mysqli($host, $user, $pass, $db);

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "DB connection failed"]);
    exit;
}

$data = json_decode(file_get_contents("php://input"), true);
$menu_id = $data['menu_id'] ?? null;
$ingredients = $data['ingredients'] ?? [];

if (!$menu_id || empty($ingredients)) {
    echo json_encode(["success" => false, "message" => "Missing menu_id or ingredients"]);
    exit;
}

// delete old ingredients for this menu item
$conn->query("DELETE FROM menu_ingredients WHERE menu_id = '$menu_id'");

// insert new ones
$stmt = $conn->prepare("
    INSERT INTO menu_ingredients (menu_id, material_id, quantity, unit, expiration_date)
    VALUES (?, ?, ?, ?, ?)
");

foreach ($ingredients as $ing) {
    $material_id = $ing['material_id'];
    $quantity = $ing['quantity'];
    $unit = $ing['unit'];
    $expiration = $ing['expiration'] ?: null;

    $stmt->bind_param("iidss", $menu_id, $material_id, $quantity, $unit, $expiration);
    $stmt->execute();
}

echo json_encode(["success" => true, "message" => "Ingredients saved successfully."]);
$stmt->close();
$conn->close();
?>
