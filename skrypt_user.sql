DROP USER IF EXISTS 'Klient'@'localhost';
CREATE USER 'Klient'@'localhost';
SET PASSWORD FOR 'Klient'@'localhost' ='1234';
GRANT EXECUTE ON PROCEDURE klinika.wolne_miejsca
TO 'Klient'@'localhost';
FLUSH PRIVILEGES;