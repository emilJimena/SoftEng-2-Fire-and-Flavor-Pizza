<?php
header("Content-Type: application/json");
include("../db.php");

$materials = [];
$res = $conn->query("SELECT * FROM raw_materials");
while ($row = $res->fetch_assoc()) {
    $materialId = $row['id'];
    $entriesRes = $conn->query("SELECT * FROM raw_material_stock_entries WHERE material_id = $materialId ORDER BY added_at DESC");
    $entries = [];
    while ($entry = $entriesRes->fetch_assoc()) {
        $entries[] = $entry;
    }
    $row['entries'] = $entries;
    $materials[] = $row;
}

echo json_encode(["success" => true, "materials" => $materials]);
$conn->close();
