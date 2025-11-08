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
    "toppings" => [],
    "pastaAddons" => [],
    "riceAddons" => []
];

// --- SQL with proper ordering ---
$query = "
SELECT * FROM addons_list
ORDER BY 
    subcategory,
    CASE 
        -- Sizes order: Small → Extra Large
        WHEN subcategory = 'Sizes' AND name = 'Small' THEN 0
        WHEN subcategory = 'Sizes' AND name = 'Medium' THEN 1
        WHEN subcategory = 'Sizes' AND name = 'Large' THEN 2
        WHEN subcategory = 'Sizes' AND name = 'Extra Large' THEN 3

        -- Stuffed Crust: None first
        WHEN subcategory = 'Stuffed Crust Option' AND name = 'None' THEN 0
        WHEN subcategory = 'Stuffed Crust Option' AND name = 'Cheese burst' THEN 1
        WHEN subcategory = 'Stuffed Crust Option' AND name = 'Cheddar stuffed' THEN 2
        WHEN subcategory = 'Stuffed Crust Option' AND name = 'Mozzarella stuffed' THEN 3
        WHEN subcategory = 'Stuffed Crust Option' AND name = 'Spinach & cheese stuffed' THEN 4
        WHEN subcategory = 'Stuffed Crust Option' AND name = 'Garlic butter stuffed' THEN 5

        ELSE 99
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
            case 'Toppings':
                $addons['toppings'][$name] = $price;
                break;
            case 'Cheese Addons':
            case 'Sauce & Flavor Addons':
            case 'Side Addons':
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
