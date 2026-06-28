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

if (!isset($_FILES['design']) || !is_uploaded_file($_FILES['design']['tmp_name'])) {
  http_response_code(400);
  echo json_encode(['error' => 'Design file is required']);
  exit;
}

$filename = isset($_POST['filename']) && $_POST['filename'] !== ''
  ? preg_replace('/[^A-Za-z0-9_.-]/', '', $_POST['filename'])
  : 'design-' . time();

$targetDir = __DIR__ . '/../designs';
if (!is_dir($targetDir) && !mkdir($targetDir, 0755, true)) {
  http_response_code(500);
  echo json_encode(['error' => 'Unable to create designs directory']);
  exit;
}

$originalName = $_FILES['design']['name'] ?? 'design';
$extension = strtolower(pathinfo($originalName, PATHINFO_EXTENSION));
if ($extension === '') {
  $extension = 'jpg';
}

$allowedExtensions = ['jpg', 'jpeg', 'png', 'pdf'];
if (!in_array($extension, $allowedExtensions, true)) {
  http_response_code(400);
  echo json_encode(['error' => 'Unsupported design format']);
  exit;
}

// Ensure filename has an extension.
if (!preg_match('/\.[A-Za-z0-9]+$/', $filename)) {
  $filename = $filename . '.' . $extension;
}

$targetName = $filename;
$targetPath = $targetDir . '/' . $targetName;

if (!move_uploaded_file($_FILES['design']['tmp_name'], $targetPath)) {
  http_response_code(500);
  echo json_encode(['error' => 'Failed to save uploaded design']);
  exit;
}

$scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
$host = $_SERVER['HTTP_HOST'] ?? 'localhost';
$designUrl = $scheme . '://' . $host . '/printx/designs/' . rawurlencode($targetName);

// Return both URL and final filename.
echo json_encode(['url' => $designUrl, 'filename' => $targetName]);


