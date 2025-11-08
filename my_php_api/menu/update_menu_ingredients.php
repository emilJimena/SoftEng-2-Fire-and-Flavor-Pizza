<?php
header('Content-Type: application/json');
include("../db.php"); // Make sure this connects to your database

// Get JSON input
$input = json_decode(file_get_contents('php://input'), true);

$menu_id = $input['menu_id'] ?? null;
$ingredients = $input['ingredients'] ?? [];

if (!$menu_id) {
    echo json_encode([
        'success' => false,
        'message' => 'Menu ID is required'
    ]);
    exit;
}

// Start transaction
$conn->begin_transaction();

try {
    // Optional: delete existing ingredients for this menu
    $stmt = $conn->prepare("DELETE FROM menu_ingredients WHERE menu_id = ?");
    $stmt->bind_param("i", $menu_id);
    $stmt->execute();

    // Insert new ingredients
    $stmt = $conn->prepare(
        "INSERT INTO menu_ingredients (menu_id, material_id, quantity) VALUES (?, ?, ?)"
    );

    foreach ($ingredients as $ing) {
        $material_id = $ing['material_id'];
        $quantity = $ing['quantity'] ?? 0;

        $stmt->bind_param("iid", $menu_id, $material_id, $quantity);
        $stmt->execute();
    }

    $conn->commit();

    echo json_encode([
        'success' => true,
        'message' => 'Ingredients updated successfully'
    ]);

} catch (Exception $e) {
    $conn->rollback();
    echo json_encode([
        'success' => false,
        'message' => 'Failed to update ingredients: ' . $e->getMessage()
    ]);
}

$stmt->close();
$conn->close();
