<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

include("../db.php"); // Database connection

if ($_SERVER["REQUEST_METHOD"] === "POST") {
    $data = json_decode(file_get_contents("php://input"), true);

    if (!$data || !isset($data['items'])) {
        echo json_encode(["success" => false, "message" => "No valid order data received"]);
        exit;
    }

    // Clean and extract order info
    $orderName = $conn->real_escape_string($data['orderName'] ?? 'Customer Order');
    $orderDate = $conn->real_escape_string($data['orderDate'] ?? date("Y-m-d"));
    $orderTime = $conn->real_escape_string($data['orderTime'] ?? date("H:i:s"));
    $paymentMethod = $conn->real_escape_string($data['paymentMethod'] ?? 'Cash');
    $items = $data['items'];

    // Ensure payment_method column exists
    $checkColumn = $conn->query("SHOW COLUMNS FROM orders LIKE 'payment_method'");
    if ($checkColumn->num_rows === 0) {
        echo json_encode(["success" => false, "message" => "Database missing 'payment_method' column"]);
        exit;
    }

    // Insert into orders table
    $stmt = $conn->prepare("
        INSERT INTO orders (order_name, order_date, order_time, payment_method) 
        VALUES (?, ?, ?, ?)
    ");

    if (!$stmt) {
        echo json_encode(["success" => false, "message" => "Prepare failed: " . $conn->error]);
        exit;
    }

    $stmt->bind_param("ssss", $orderName, $orderDate, $orderTime, $paymentMethod);

    if (!$stmt->execute()) {
        echo json_encode(["success" => false, "message" => "Execute failed: " . $stmt->error]);
        exit;
    }

    $orderId = $stmt->insert_id;
    $stmt->close();

    // Insert order items
    $item_stmt = $conn->prepare("
        INSERT INTO order_items (order_id, menu_item, category, quantity, size, price, addons)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ");

    if (!$item_stmt) {
        echo json_encode(["success" => false, "message" => "Item prepare failed: " . $conn->error]);
        exit;
    }

    foreach ($items as $item) {
        $menu_item = $conn->real_escape_string($item['menuItem'] ?? '');
        $category = $conn->real_escape_string($item['category'] ?? '');
        $quantity = (int)($item['quantity'] ?? 1);
        $size = $conn->real_escape_string($item['size'] ?? '');
        $price = (float)($item['price'] ?? 0);
        $addons = json_encode($item['addons'] ?? []);

        $item_stmt->bind_param("issisds", $orderId, $menu_item, $category, $quantity, $size, $price, $addons);

        if (!$item_stmt->execute()) {
            echo json_encode(["success" => false, "message" => "Item execute failed: " . $item_stmt->error]);
            $item_stmt->close();
            $conn->close();
            exit;
        }
    }

    $item_stmt->close();
    $conn->close();

    echo json_encode([
        "success" => true,
        "message" => "Order saved successfully",
        "order_id" => $orderId,
        "paymentMethod" => $paymentMethod
    ]);
} else {
    echo json_encode(["success" => false, "message" => "Invalid request method"]);
}
?>
