<?php
/*
 * Apache only supports 'automatic' syntax highlighting of .phps files via the
 * `mod_php` extension. If a hosting provider is running PHP through FPM or
 * FastCGI, the `.htaccess` approach of simply adding
 * `RewriteRule ^(.+\.php)s$ $1 [H=application/x-httpd-php-source]` doesn't
 * work. The workaround is to have another PHP script act as the syntax
 * highlighter for a requested .phps file.
 *
 * This opens up **ALL KINDS** of nasty security vulnerabilities if done
 * incorrectly, because the highlighter script could be enticed to try
 * highligting a file outside of the web root directory, such as
 * `/etc/passwd` for example. So THIS script is hardcoded to be a corollary
 * to the only other PHP file in this project. (The mod_php handler approach
 * is WAY more elegant though, if you ask me.)
 */

// Make sure the browser renders the result instead of downloading it.
header('Content-Type: text/html');

// We get a `$_GET['file'] param from the `.htaccess` redirect, but using
// it is fraught with danger, so hardcode the source `.php` file we want to
// highlight and ignore the GET param entirely.
highlight_file('./gravatarize.php');

// Not needed, but it doesn't hurt to make it explicit that this script
// _shouldn't_ try to do anything else.
exit;
