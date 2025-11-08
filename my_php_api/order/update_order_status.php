<?php
header("Content-Type: application/json");

// Enable strict error reporting for debugging (optional, remove in production)
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

include("../db.php");

try {
    // Get POST inputs safely
    $order_id = isset($_POST['order_id']) ? (int) $_POST['order_id'] : 0;
    $status = isset($_POST['status']) ? trim($_POST['status']) : '';

    $allowed_status = ['pending', 'processing', 'completed', 'cancelled'];

    if ($order_id === 0 || !in_array($status, $allowed_status)) {
        throw new Exception("Invalid input");
    }

    // Prepare and execute update statement
    $stmt = $conn->prepare("UPDATE customer_orders SET status = ? WHERE id = ?");
    if (!$stmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }

    $stmt->bind_param("si", $status, $order_id);
    $success = $stmt->execute();

    if (!$success) {
        throw new Exception("Execute failed: " . $stmt->error);
    }

    echo json_encode([
        "success" => true,
        "message" => "Order status updated successfully"
    ]);

    $stmt->close();

} catch (Exception $e) {
    echo json_encode([
        "success" => false,
        "message" => $e->getMessage()
    ]);
} finally {
    $conn->close();
}
