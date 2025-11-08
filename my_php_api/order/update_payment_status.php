<?php
header("Content-Type: application/json");
include("../db.php");

$order_id = $_POST['order_id'] ?? 0;
$payment_method = $_POST['payment_method'] ?? '';
$payment_status = $_POST['payment_status'] ?? '';

if ($order_id == 0 || $payment_method == '' || $payment_status == '') {
    echo json_encode(["success" => false, "message" => "Invalid input"]);
    exit;
}

$stmt = $conn->prepare("
    UPDATE customer_orders 
    SET payment_method = ?, payment_status = ? 
    WHERE id = ?
");
$stmt->bind_param("ssi", $payment_method, $payment_status, $order_id);
$success = $stmt->execute();

echo json_encode(["success" => $success]);
$stmt->close();
$conn->close();
?>
