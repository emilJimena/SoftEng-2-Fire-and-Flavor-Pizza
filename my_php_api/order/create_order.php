<?php
header("Content-Type: application/json");
include("../db.php");

try {
    $input = json_decode(file_get_contents("php://input"), true);

    $user_id = $input['user_id'] ?? 0;
    $order_items = $input['items'] ?? [];
    $total_amount = $input['total_amount'] ?? 0;
    $status = $input['status'] ?? 'pending';
    $availability = $input['availability'] ?? 'available';
    $payment_method = $input['payment_method'] ?? 'Cash';
    $payment_status = $input['payment_status'] ?? 'unpaid';

    if ($user_id <= 0 || empty($order_items)) {
        echo json_encode(["success" => false, "message" => "Missing user ID or order items"]);
        exit;
    }

    // Step 1: Check stock availability
    $insufficient = [];
    foreach ($order_items as $item) {
        $menu_id = $item['id'] ?? null;
        $quantityOrdered = (int)($item['quantity'] ?? 0);
        if (!$menu_id || $quantityOrdered <= 0) continue;

        // Get ingredients for this menu item
        $ingStmt = $conn->prepare("SELECT material_id, quantity FROM menu_ingredients WHERE menu_id = ?");
        $ingStmt->bind_param("i", $menu_id);
        $ingStmt->execute();
        $ingResult = $ingStmt->get_result();

        while ($ingredient = $ingResult->fetch_assoc()) {
            $material_id = $ingredient['material_id'];
            $ingredient_qty = (float)$ingredient['quantity'];
            $totalRequired = $ingredient_qty * $quantityOrdered;

            // Get current stock
            $stockStmt = $conn->prepare("SELECT stock, name FROM raw_materials WHERE id = ?");
            $stockStmt->bind_param("i", $material_id);
            $stockStmt->execute();
            $stockData = $stockStmt->get_result()->fetch_assoc();
            $stockStmt->close();

            if (($stockData['stock'] ?? 0) < $totalRequired) {
                $insufficient[] = "{$stockData['name']} (needed: $totalRequired, available: {$stockData['stock']})";
            }
        }

        $ingStmt->close();
    }

    if (!empty($insufficient)) {
        echo json_encode([
            "success" => false,
            "message" => "Insufficient stock for: " . implode(", ", $insufficient)
        ]);
        exit;
    }

    // Step 2: Insert the order
    $order_items_json = json_encode($order_items);
    $stmt = $conn->prepare("
        INSERT INTO customer_orders
        (user_id, order_items, total_amount, status, availability, payment_method, payment_status)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ");
    $stmt->bind_param(
        "isdssss",
        $user_id,
        $order_items_json,
        $total_amount,
        $status,
        $availability,
        $payment_method,
        $payment_status
    );
    if (!$stmt->execute()) {
        echo json_encode(["success" => false, "message" => "Database error: " . $conn->error]);
        exit;
    }
    $order_id = $conn->insert_id;
    $stmt->close();

    // Step 3: Deduct stock from raw_materials
    foreach ($order_items as $item) {
        $menu_id = $item['id'] ?? null;
        $quantityOrdered = (int)($item['quantity'] ?? 0);
        if (!$menu_id || $quantityOrdered <= 0) continue;

        $ingStmt = $conn->prepare("SELECT material_id, quantity FROM menu_ingredients WHERE menu_id = ?");
        $ingStmt->bind_param("i", $menu_id);
        $ingStmt->execute();
        $ingResult = $ingStmt->get_result();

        while ($ingredient = $ingResult->fetch_assoc()) {
            $material_id = $ingredient['material_id'];
            $ingredient_qty = (float)$ingredient['quantity'];
            $totalDeduction = $ingredient_qty * $quantityOrdered;

            $updateStmt = $conn->prepare("
                UPDATE raw_materials
                SET stock = GREATEST(stock - ?, 0)
                WHERE id = ?
            ");
            $updateStmt->bind_param("di", $totalDeduction, $material_id);
            $updateStmt->execute();
            $updateStmt->close();
        }

        $ingStmt->close();
    }

    echo json_encode([
        "success" => true,
        "message" => "Order placed successfully and stock updated",
        "order_id" => $order_id
    ]);

} catch (Exception $e) {
    echo json_encode(["success" => false, "message" => $e->getMessage()]);
} finally {
    $conn->close();
}
?>
