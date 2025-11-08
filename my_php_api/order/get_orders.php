<?php
header("Content-Type: application/json");
include("../db.php");

try {
    $user_id = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;

    // ✅ If no user_id is passed, return ALL orders (for managers)
    $sql = "
        SELECT o.*, u.email AS user_email
        FROM customer_orders o
        LEFT JOIN users u ON o.user_id = u.id
    ";

    if ($user_id > 0) {
        $sql .= " WHERE o.user_id = ?";
    }

    $sql .= " ORDER BY o.created_at DESC";

    $stmt = $conn->prepare($sql);

    if ($user_id > 0) {
        $stmt->bind_param("i", $user_id);
    }

    $stmt->execute();
    $result = $stmt->get_result();

    $orders = [];
    while ($row = $result->fetch_assoc()) {
        $orders[] = [
            "id" => (int)$row['id'],
            "user_id" => (int)$row['user_id'],
            "user_email" => $row['user_email'] ?? 'Unknown',
            "order_items" => json_decode($row['order_items'], true),
            "total_amount" => (float)$row['total_amount'],
            "status" => $row['status'],
            "availability" => $row['availability'],
            "payment_method" => $row['payment_method'],
            "payment_status" => $row['payment_status'],
            "created_at" => $row['created_at']
        ];
    }

    echo json_encode(["success" => true, "orders" => $orders]);
} catch (Exception $e) {
    echo json_encode(["success" => false, "message" => $e->getMessage()]);
} finally {
    $conn->close();
}
?>
