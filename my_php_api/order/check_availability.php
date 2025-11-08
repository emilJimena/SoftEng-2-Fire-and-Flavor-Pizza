<?php
header("Content-Type: application/json");
include("../db.php");

$order_id = $_POST['order_id'] ?? 0;

if ($order_id == 0) {
    echo json_encode(["success" => false, "message" => "Missing order ID"]);
    exit;
}

// Step 1: Get order details (menu_id and quantity)
$stmt = $conn->prepare("SELECT menu_id, quantity FROM customer_orders WHERE id = ?");
$stmt->bind_param("i", $order_id);
$stmt->execute();
$order = $stmt->get_result()->fetch_assoc();
$stmt->close();

if (!$order) {
    echo json_encode(["success" => false, "message" => "Order not found"]);
    exit;
}

$menu_id = $order["menu_id"];
$order_qty = floatval($order["quantity"]);

// Step 2: Get ingredients for the menu item
$stmt = $conn->prepare("
    SELECT 
        rm.id AS material_id,
        rm.name AS material_name,
        rm.quantity AS available_stock,
        mi.quantity AS required_per_item
    FROM menu_ingredients mi
    JOIN raw_materials rm ON mi.material_id = rm.id
    WHERE mi.menu_id = ?
");
$stmt->bind_param("i", $menu_id);
$stmt->execute();
$ingredients = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
$stmt->close();

if (empty($ingredients)) {
    echo json_encode(["success" => false, "message" => "No ingredients found for this menu item"]);
    exit;
}

// Step 3: Check stock availability
$allAvailable = true;
foreach ($ingredients as $ing) {
    $requiredTotal = floatval($ing["required_per_item"]) * $order_qty;
    $available = floatval($ing["available_stock"]);

    if ($available < $requiredTotal) {
        $allAvailable = false;
        break;
    }
}

// Step 4: Update order status
$newStatus = $allAvailable ? 'available' : 'unavailable';
$update = $conn->prepare("UPDATE customer_orders SET status = ? WHERE id = ?");
$update->bind_param("si", $newStatus, $order_id);
$update->execute();
$update->close();

echo json_encode([
    "success" => true,
    "message" => $allAvailable
        ? "Order #$order_id is available"
        : "Order #$order_id is unavailable due to insufficient materials",
    "status" => $newStatus
]);

$conn->close();
?>
