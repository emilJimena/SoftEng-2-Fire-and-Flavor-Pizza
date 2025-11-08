<?php
header('Content-Type: application/json');
error_reporting(E_ALL);
ini_set('display_errors', 1);
include '../db.php';

$input = json_decode(file_get_contents('php://input'), true);
$items = $input['items'] ?? [];
$user_id = intval($input['user_id'] ?? 0);
$reason = trim($input['reason'] ?? 'Auto Deduction(Main Ingredients)');

if (empty($items)) {
    echo json_encode(['success' => false, 'message' => 'No ingredients to deduct']);
    exit;
}

if (!$conn) {
    echo json_encode(['success' => false, 'message' => 'Database connection failed']);
    exit;
}

// ✅ Validate user exists
$userCheck = $conn->prepare("SELECT id FROM users WHERE id = ?");
$userCheck->bind_param("i", $user_id);
$userCheck->execute();
$userResult = $userCheck->get_result();
if ($userResult->num_rows === 0) {
    echo json_encode(['success' => false, 'message' => 'Invalid user ID']);
    exit;
}
$userCheck->close();

$conn->begin_transaction();
try {
    foreach ($items as $item) {
        $menuIngredientId = intval($item['id'] ?? 0);
        $amount = floatval($item['amount'] ?? 0);
        if ($menuIngredientId <= 0 || $amount <= 0) continue;

        // 🔹 Get material info
        $checkStmt = $conn->prepare("
            SELECT rm.id AS material_id, rm.name, rm.unit, rm.quantity
            FROM raw_materials rm
            INNER JOIN menu_ingredients mi ON mi.material_id = rm.id
            WHERE mi.id = ?
            FOR UPDATE
        ");
        if (!$checkStmt) throw new Exception("Prepare failed: " . $conn->error);

        $checkStmt->bind_param("i", $menuIngredientId);
        $checkStmt->execute();
        $res = $checkStmt->get_result();
        $row = $res->fetch_assoc();
        $checkStmt->close();

        if (!$row) throw new Exception("Ingredient not found for ID: $menuIngredientId");

        $material_id = $row['material_id'];
        $materialName = $row['name'];
        $unit = $row['unit'];
        $currentQty = floatval($row['quantity']);

        if ($currentQty < $amount)
            throw new Exception("Insufficient stock for $materialName");

        // 🔹 Deduct stock
        $deductStmt = $conn->prepare("UPDATE raw_materials SET quantity = quantity - ? WHERE id = ?");
        if (!$deductStmt) throw new Exception("Deduct prepare failed: " . $conn->error);
        $deductStmt->bind_param("di", $amount, $material_id);
        $deductStmt->execute();
        $deductStmt->close();

        // 🔹 Log deduction
        $logStmt = $conn->prepare("
            INSERT INTO inventory_log (material_id, quantity, unit, expiration_date, reason, user_id)
            VALUES (?, ?, ?, NULL, ?, ?)
        ");
        if (!$logStmt) throw new Exception("Log prepare failed: " . $conn->error);

        $negQty = -$amount;
        $logStmt->bind_param("idssi", $material_id, $negQty, $unit, $reason, $user_id);

        if (!$logStmt->execute()) {
            throw new Exception("Log insert failed for $materialName: " . $logStmt->error);
        }

        $logStmt->close();
    }

    $conn->commit();
    echo json_encode(['success' => true, 'message' => 'Main ingredients deducted and logged']);
} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(['success' => false, 'message' => 'Deduction failed: ' . $e->getMessage()]);
}
?>