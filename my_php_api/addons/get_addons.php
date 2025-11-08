<?php
// --- Response headers (CORS + JSON) ---
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// --- Include database connection ---
include("../db.php");

// --- Initialize structured response with arrays ---
$addons = [
    "sizes" => [],
    "crusts" => [],
    "dips" => [],
    "stuffed" => [],
    "pizzaAddons" => [],
    "pastaAddons" => [],
    "riceAddons" => []
];

// --- Query all addons ---
$query = "
SELECT * FROM addons_list
ORDER BY 
    category,
    CASE 
        WHEN category = 'Size' AND name = 'Small' THEN 0 
        WHEN category = 'Size' AND name = 'Medium' THEN 1
        WHEN category = 'Size' AND name = 'Large' THEN 2
        WHEN category = 'Size' AND name = 'Extra Large' THEN 3
        WHEN category = 'Stuffed' AND name = 'None' THEN 0
        ELSE 4
    END,
    name
";
$result = $conn->query($query);

if ($result && $result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $category = $row['category'] ?? '';
        $subcategory = $row['subcategory'] ?? '';
        $name = $row['name'] ?? '';
        $price = floatval($row['price'] ?? 0);

        switch ($category) {
            case 'Size':
                $addons['sizes'][$name] = $price;
                break;

            case 'Crust':
                $addons['crusts'][$name] = $price;
                break;

            case 'Dip':
                $addons['dips'][$name] = $price;
                break;

            case 'Stuffed':
                $addons['stuffed'][$name] = $price;
                break;

            case 'Pizza Addons':
                $addons['pizzaAddons'][$name] = $price;
                break;

            case 'Pasta Addons':
                if ($subcategory) {
                    if (!isset($addons['pastaAddons'][$subcategory])) {
                        $addons['pastaAddons'][$subcategory] = [];
                    }
                    $addons['pastaAddons'][$subcategory][$name] = $price;
                }
                break;

            case 'Rice Addons':
                if ($subcategory) {
                    if (!isset($addons['riceAddons'][$subcategory])) {
                        $addons['riceAddons'][$subcategory] = [];
                    }
                    $addons['riceAddons'][$subcategory][$name] = $price;
                }
                break;
        }
    }
}

// --- Output final structured JSON ---
echo json_encode($addons, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);

// --- Close database connection ---
$conn->close();
exit();
?>
