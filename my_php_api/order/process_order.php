<?php
header("Content-Type: application/json");
include("../db.php");

$data = json_decode(file_get_contents("php://input"), true);

$menu_id = intval($data['menu_id'] ?? 0);
$quantity = intval($data['quantity'] ?? 1);

if ($menu_id <= 0 || $quantity <= 0) {
    echo json_encode(["success" => false, "message" => "Invalid menu ID or quantity"]);
    exit;
}

// Fetch the menu item
$menuStmt = $conn->prepare("SELECT name FROM menu_items WHERE id = ?");
$menuStmt->bind_param("i", $menu_id);
$menuStmt->execute();
$menuResult = $menuStmt->get_result();
$menu = $menuResult->fetch_assoc();
if (!$menu) {
    echo json_encode(["success" => false, "message" => "Menu item not found"]);
    exit;
}

// Fetch ingredients linked to that menu
$sql = "
    SELECT mi.material_id, mi.quantity, rm.stock, rm.name, rm.unit
    FROM menu_ingredients mi
    JOIN raw_materials rm ON rm.id = mi.material_id
    WHERE mi.menu_id = ?
";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $menu_id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    echo json_encode(["success" => false, "message" => "No ingredients linked to this menu item"]);
    exit;
}

// Check stock availability
$updates = [];
while ($row = $result->fetch_assoc()) {
    $neededQty = $row['quantity'] * $quantity;
    $remainingStock = $row['stock'] - $neededQty;

    if ($remainingStock < 0) {
        echo json_encode([
            "success" => false,
            "message" => "Insufficient stock for '{$row['name']}'. Need {$neededQty} {$row['unit']}, only {$row['stock']} left."
        ]);
        exit;
    }

    $updates[] = [
        'material_id' => $row['material_id'],
        'new_stock' => $remainingStock
    ];
}

// Deduct stocks
$conn->begin_transaction();
try {
    foreach ($updates as $u) {
        $updateStmt = $conn->prepare("UPDATE raw_materials SET stock = ? WHERE id = ?");
        $updateStmt->bind_param("di", $u['new_stock'], $u['material_id']);
        $updateStmt->execute();
    }

    $conn->commit();
    echo json_encode([
        "success" => true,
        "message" => "Order processed successfully. Stock updated for '{$menu['name']}'."
    ]);
} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(["success" => false, "message" => "Error updating stock: " . $e->getMessage()]);
}

$stmt->close();
$conn->close();
?>
