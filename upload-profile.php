<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
  http_response_code(204);
  exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
  http_response_code(405);
  echo json_encode(['error' => 'Method not allowed']);
  exit;
}

if (!isset($_FILES['image']) || !is_uploaded_file($_FILES['image']['tmp_name'])) {
  http_response_code(400);
  echo json_encode(['error' => 'Image file is required']);
  exit;
}

$filename = isset($_POST['filename']) && $_POST['filename'] !== ''
  ? preg_replace('/[^A-Za-z0-9_.-]/', '', $_POST['filename'])
  : 'profile-' . time() . '.jpg';

$targetDir = __DIR__ . '/../profiles';
if (!is_dir($targetDir) && !mkdir($targetDir, 0755, true)) {
  http_response_code(500);
  echo json_encode(['error' => 'Unable to create profiles directory']);
  exit;
}

$originalName = $_FILES['image']['name'] ?? 'image.jpg';
$extension = strtolower(pathinfo($originalName, PATHINFO_EXTENSION));
if ($extension === '') {
  $extension = 'jpg';
}

$allowedExtensions = ['jpg', 'jpeg', 'png', 'webp', 'gif'];
if (!in_array($extension, $allowedExtensions, true)) {
  http_response_code(400);
  echo json_encode(['error' => 'Unsupported image format']);
  exit;
}

// Ensure filename has an extension; if not, append detected extension.
if (!preg_match('/\.[A-Za-z0-9]+$/', $filename)) {
  $filename = $filename . '.' . $extension;
}

$targetName = $filename;
$targetPath = $targetDir . '/' . $targetName;

if (!move_uploaded_file($_FILES['image']['tmp_name'], $targetPath)) {
  http_response_code(500);
  echo json_encode(['error' => 'Failed to save uploaded image']);
  exit;
}

$scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
$host = $_SERVER['HTTP_HOST'] ?? 'localhost';
$imageUrl = $scheme . '://' . $host . '/printx/profiles/' . rawurlencode($targetName);

echo json_encode(['url' => $imageUrl, 'filename' => $targetName]);

