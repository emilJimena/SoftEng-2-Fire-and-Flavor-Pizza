<?php
header("Content-Type: application/json");
include("../db.php");

$data = json_decode(file_get_contents("php://input"), true);

$id = intval($data['id'] ?? 0);
$quantity = floatval($data['quantity'] ?? 0);
$expiration_date = $data['expiration_date'] ?? null;

if ($id <= 0 || $quantity <= 0) {
    echo json_encode(["success" => false, "message" => "Invalid ID or quantity"]);
    exit;
}

// If expiration_date is null or empty string, set to SQL NULL
if (empty($expiration_date)) {
    $sql = "UPDATE raw_material_stock_entries SET quantity = ?, expiration_date = NULL WHERE id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("di", $quantity, $id);
} else {
    $sql = "UPDATE raw_material_stock_entries SET quantity = ?, expiration_date = ? WHERE id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("dsi", $quantity, $expiration_date, $id);
}

if ($stmt->execute()) {
    echo json_encode(["success" => true, "message" => "Stock entry updated successfully"]);
} else {
    echo json_encode(["success" => false, "message" => $stmt->error]);
}

$stmt->close();
$conn->close();
?>
