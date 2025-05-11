<?php
/*
 * Look for a GET[email] variable.
 * When not present or invalid, redirect to /index.html.
 * When present, strip whitespace, lowercase, sha256, redirect to gravatar url.
 */
declare(strict_types=1);

function redirect(string $destination) {
  header("Location: $destination", true, 301);
  exit;
}

function input(): string {
  $email = mb_trim($_GET['email'] ?? '', null, 'UTF-8');

  if (mb_strlen($email) === 0 || ! filter_var($email, FILTER_VALIDATE_EMAIL)) {
    redirect('/index.html');
  }

  return mb_strtolower($email, 'UTF-8');
}

function gravatarize(string $email): string {
  return hash('sha256', mb_strtolower($email, 'UTF-8'));
}

// main()
const BASE_URL = 'https://gravatar.com/avatar/';
const OPTS = [
  'd' => 'identicon',
  's' => 200,
];

redirect(BASE_URL . gravatarize(input()) . '?' . http_build_query(OPTS));
exit;
