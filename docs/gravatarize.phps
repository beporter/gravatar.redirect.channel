<?php
/*
 * Apache only supports 'automatic' syntax highlighting of .phps files via the
 * `mod_php` extension. If a hosting provider is running PHP through FPM or
 * FastCGI, the `.htaccess` approach of adding
 * `RewriteRule ^(.+\.php)s$ $1 [H=application/x-httpd-php-source]` doesn't
 * work. The workaround is to have another PHP script act as the syntax h
 * ighlighter for a requested .phps file.
 *
 * This opens up **ALL KINDS** of nasty security vulnerabilities if done
 * incorrectly, because the highlighter script could be enticed to try
 * highligting a file outside of the web root directory, such as
 * `/etc/passwd` for example. So THIS script is hardcoded to be a corollary
 * to the only other PHP file in this project. (The mod_php handler approach
 * is WAY more elegant though, if you ask me.)
 */

// As long as this file is named the same as the file you want to highlight
// (just with an added trailing 's'), it can be dropped in anywhere without
// further modification.
highlight_file(basename(__FILE__), 's');

// Not needed, but it doesn't hurt to make it explicit that this script
// _shouldn't_ try to do anything else.
exit;
