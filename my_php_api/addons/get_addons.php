<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

include("../db.php");

$addons = [
    "sizes" => [],
    "crusts" => [],
    "dips" => [],
    "stuffed" => [],
    "pizzaAddons" => [],
    "pastaAddons" => [],
    "riceAddons" => []
];

// --- Keep your ordering query ---
$query = "
SELECT * FROM addons_list
ORDER BY 
    category,
    CASE 
        -- Sizes ordered Small → Extra Large
        WHEN subcategory = 'Sizes' AND name = 'Small' THEN 0
        WHEN subcategory = 'Sizes' AND name = 'Medium' THEN 1
        WHEN subcategory = 'Sizes' AND name = 'Large' THEN 2
        WHEN subcategory = 'Sizes' AND name = 'Extra Large' THEN 3
        -- Stuffed Crust Option: None first
        WHEN subcategory = 'Stuffed Crust Option' AND name = 'None' THEN 0
        ELSE 4
    END,
    name
";

$result = $conn->query($query);

if ($result && $result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $subcategory = $row['subcategory'] ?? '';
        $name = $row['name'] ?? '';
        $price = floatval($row['price'] ?? 0);
        $category = $row['category'] ?? '';

        // Map based on subcategory
        switch ($subcategory) {
            case 'Sizes':
                $addons['sizes'][$name] = $price;
                break;
            case 'Crust Type':
                $addons['crusts'][$name] = $price;
                break;
            case 'Side Dips':
                $addons['dips'][$name] = $price;
                break;
            case 'Stuffed Crust Option':
                $addons['stuffed'][$name] = $price;
                break;
            case 'Pizza Addons':
                $addons['pizzaAddons'][$name] = $price;
                break;
            case 'Cheese Addons':
            case 'Sauce & Flavor Addons':
            case 'Side Addons':
                // For pasta/rice, group by subcategory
                if (stripos($category, 'pasta') !== false) {
                    if (!isset($addons['pastaAddons'][$subcategory])) $addons['pastaAddons'][$subcategory] = [];
                    $addons['pastaAddons'][$subcategory][$name] = $price;
                }
                if (stripos($category, 'rice') !== false) {
                    if (!isset($addons['riceAddons'][$subcategory])) $addons['riceAddons'][$subcategory] = [];
                    $addons['riceAddons'][$subcategory][$name] = $price;
                }
                break;
        }
    }
}

echo json_encode($addons, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
$conn->close();
exit();
?>
