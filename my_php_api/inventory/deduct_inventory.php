<?php
header("Access-Control-Allow-Origin: *"); 
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");
include("../db.php");

$input = json_decode(file_get_contents('php://input'), true);
$names = $input['name'] ?? [];
$amounts = $input['amount'] ?? [];
$user_id = intval($input['user_id'] ?? 0);
$reason = trim($input['reason'] ?? 'Auto Deduction(Addons)');

if (!is_array($names) || !is_array($amounts) || count($names) !== count($amounts)) {
    echo json_encode(["success" => false, "message" => "Invalid input"]);
    exit;
}

// ✅ Validate user exists
$userCheck = $conn->prepare("SELECT id FROM users WHERE id = ?");
$userCheck->bind_param("i", $user_id);
$userCheck->execute();
$userResult = $userCheck->get_result();
if ($userResult->num_rows === 0) {
    echo json_encode(["success" => false, "message" => "Invalid user ID"]);
    exit;
}
$userCheck->close();

try {
    $conn->begin_transaction();
    $messages = [];

    for ($i = 0; $i < count($names); $i++) {
        $name = trim($names[$i]);
        $amount = floatval($amounts[$i]);

        if (empty($name) || $amount <= 0) {
            $messages[] = "Invalid name or amount at index $i";
            continue;
        }

        // 🔹 Find material info
        $matStmt = $conn->prepare("SELECT id, unit FROM raw_materials WHERE name = ?");
        if (!$matStmt) throw new Exception("Material query failed: " . $conn->error);
        $matStmt->bind_param("s", $name);
        $matStmt->execute();
        $material = $matStmt->get_result()->fetch_assoc();
        $matStmt->close();

        if (!$material) {
            $messages[] = "Material not found: $name";
            continue;
        }

        $material_id = intval($material['id']);
        $unit = $material['unit'] ?? '';

        // 🔹 Deduct stock
        $stmt = $conn->prepare("UPDATE raw_materials SET quantity = quantity - ? WHERE id = ? AND quantity >= ?");
        if (!$stmt) throw new Exception("Deduction query failed: " . $conn->error);

        $stmt->bind_param("ddi", $amount, $material_id, $amount);
        $stmt->execute();

        if ($stmt->affected_rows === 0) {
            $messages[] = "Not enough stock for $name";
        } else {
            // 🔹 Log deduction in inventory_log
            $logStmt = $conn->prepare("
                INSERT INTO inventory_log (material_id, quantity, unit, expiration_date, reason, user_id)
                VALUES (?, ?, ?, NULL, ?, ?)
            ");
            if (!$logStmt) throw new Exception("Log prepare failed: " . $conn->error);

            $negQty = -$amount;
            $logStmt->bind_param("idssi", $material_id, $negQty, $unit, $reason, $user_id);

            if (!$logStmt->execute()) {
                throw new Exception("Log insert failed for $name: " . $logStmt->error);
            }

            $logStmt->close();
        }

        $stmt->close();
    }

    if (empty($messages)) {
        $conn->commit();
        echo json_encode(["success" => true, "message" => "All add-ons deducted and logged"]);
    } else {
        $conn->rollback();
        echo json_encode(["success" => false, "message" => implode("; ", $messages)]);
    }
} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}

$conn->close();
?>