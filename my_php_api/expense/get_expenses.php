<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
include("../db.php");

$result = $conn->query("SELECT id, material, quantity, amount, supplier, receipt, DATE(date) as date FROM expenses ORDER BY date DESC");
$expenses = [];

if ($result) {
    while ($row = $result->fetch_assoc()) {
        $expenses[] = [
            'id' => $row['id'],
            'material' => $row['material'],
            'quantity' => $row['quantity'],
            'amount' => number_format((float)$row['amount'], 2),
            'supplier' => $row['supplier'],
            'receipt_url' => $row['receipt'] ? $row['receipt'] : null,
            'date' => $row['date']
        ];
    }
    echo json_encode(['success' => true, 'data' => $expenses]);
} else {
    echo json_encode(['success' => false, 'message' => 'Database error']);
}
?>
