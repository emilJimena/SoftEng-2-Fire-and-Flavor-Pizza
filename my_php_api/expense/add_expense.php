<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");
include("../db.php");

// Handle POST data
$material = $_POST['material'] ?? '';
$quantity = $_POST['quantity'] ?? '';
$amount = $_POST['amount'] ?? '';
$supplier = $_POST['supplier'] ?? '';
$receiptPath = null;

// Validate required fields
if (!$material || !$quantity || !$amount || !$supplier) {
    echo json_encode(['success' => false, 'message' => 'All fields are required']);
    exit;
}

// Handle receipt upload
if (isset($_FILES['receipt']) && $_FILES['receipt']['error'] === 0) {
    $uploadsDir = "../uploads/receipts/";
    if (!is_dir($uploadsDir)) mkdir($uploadsDir, 0755, true);

    $ext = pathinfo($_FILES['receipt']['name'], PATHINFO_EXTENSION);
    $filename = uniqid('receipt_', true) . "." . $ext;
    $targetPath = $uploadsDir . $filename;

    if (move_uploaded_file($_FILES['receipt']['tmp_name'], $targetPath)) {
        $receiptPath = "uploads/receipts/" . $filename;
    }
}

// Insert into database
$stmt = $conn->prepare("INSERT INTO expenses (material, quantity, amount, supplier, receipt) VALUES (?, ?, ?, ?, ?)");
$stmt->bind_param("ssdss", $material, $quantity, $amount, $supplier, $receiptPath);

if ($stmt->execute()) {
    echo json_encode(['success' => true, 'message' => 'Expense added successfully']);
} else {
    echo json_encode(['success' => false, 'message' => 'Database error']);
}
?>
