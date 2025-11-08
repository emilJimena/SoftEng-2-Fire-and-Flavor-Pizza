<?php
header("Content-Type: application/json");
include("../db.php");

$user_id = $_POST['user_id'] ?? 0;
$order_items_json = $_POST['order_items'] ?? '[]';
$total_amount = $_POST['total_amount'] ?? 0;

if ($user_id == 0 || empty($order_items_json)) {
    echo json_encode(["success" => false, "message" => "Invalid input"]);
    exit;
}

$stmt = $conn->prepare("
    INSERT INTO customer_orders (user_id, order_items, total_amount, status, availability, payment_status)
    VALUES (?, ?, ?, 'pending', 'available', 'unpaid')
");
$stmt->bind_param("isd", $user_id, $order_items_json, $total_amount);
$success = $stmt->execute();

echo json_encode(["success" => $success]);
$stmt->close();
$conn->close();
?>
