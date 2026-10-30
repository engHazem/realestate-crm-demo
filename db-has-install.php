<?php
// Exit 0 if the configured database already contains an EspoCRM installation.
$platform = getenv('ESPOCRM_DATABASE_PLATFORM') ?: 'Mysql';
$host = getenv('ESPOCRM_DATABASE_HOST');
$port = getenv('ESPOCRM_DATABASE_PORT');
$name = getenv('ESPOCRM_DATABASE_NAME');
try {
    if ($platform === 'Postgresql') {
        $dsn = "pgsql:host=$host;dbname=$name" . ($port ? ";port=$port" : '');
        $sql = "SELECT COUNT(*) FROM \"user\" WHERE to_regclass('public.user') IS NOT NULL";
    } else {
        $dsn = "mysql:host=$host;dbname=$name" . ($port ? ";port=$port" : '');
        $sql = "SELECT COUNT(*) FROM `user`";
    }
    for ($i = 0; $i < 20; $i++) {
        try {
            $pdo = new PDO($dsn, getenv('ESPOCRM_DATABASE_USER'), getenv('ESPOCRM_DATABASE_PASSWORD'));
            break;
        } catch (Throwable $e) {
            sleep(3);
        }
    }
    if (empty($pdo)) exit(1);
    $exists = $pdo->query($platform === 'Postgresql'
        ? "SELECT to_regclass('public.user') IS NOT NULL"
        : "SHOW TABLES LIKE 'user'")->fetchColumn();
    if (!$exists) exit(1);
    exit(((int) $pdo->query($sql)->fetchColumn()) > 0 ? 0 : 1);
} catch (Throwable $e) {
    exit(1);
}
