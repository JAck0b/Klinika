DROP TRIGGER IF EXISTS przed_insert_stan_konta;
DELIMITER //
CREATE TRIGGER przed_insert_stan_konta
  BEFORE INSERT
  ON stan_konta
  FOR EACH ROW
BEGIN
  IF NEW.saldo < 0 THEN
    SIGNAL SQLSTATE '12345'
      SET MESSAGE_TEXT = ' STAN KONTA >0 ';
  END IF;
END//
DELIMITER ;

DROP TRIGGER IF EXISTS przed_insert_zabiegi;
DELIMITER //
CREATE TRIGGER przed_insert_zabiegi
  BEFORE INSERT
  ON zabiegi
  FOR EACH ROW
BEGIN
  IF HOUR(NEW.data_zabiegu) < 8 OR HOUR(NEW.data_zabiegu) > 16 THEN
    SIGNAL SQLSTATE '12345'
      SET MESSAGE_TEXT = ' NIEPRAWIDLOWA GODZINA ZABIEGU ';
  END IF;
END//
DELIMITER ;

DROP TRIGGER IF EXISTS przed_insert_transakcje;
DELIMITER //
CREATE TRIGGER przed_insert_transakcje
  BEFORE INSERT
  ON transakcje
  FOR EACH ROW
BEGIN
  IF NEW.kwota < 0 THEN
    SIGNAL SQLSTATE '12345'
      SET MESSAGE_TEXT = ' KWOTA >= 0 ';
  END IF;
END//
DELIMITER ;

DROP TRIGGER IF EXISTS przed_insert_uslugi_rehabilitacyjne;
DELIMITER //
CREATE TRIGGER przed_insert_uslugi_rehabilitacyjne
  BEFORE INSERT
  ON uslugi_rehabilitacyjne
  FOR EACH ROW
BEGIN
  IF NEW.cena < 0 OR NEW.czas_trwania < 0 THEN
    SIGNAL SQLSTATE '12345'
      SET MESSAGE_TEXT = ' CENA >= 0  i CZAS TRWANIA >= 0';
  END IF;
END//
DELIMITER ;

DROP TRIGGER IF EXISTS przed_insert_uzytkownicy;
DELIMITER //
CREATE TRIGGER przed_insert_uzytkownicy
  BEFORE INSERT
  ON uzytkownicy
  FOR EACH ROW
BEGIN
  IF NEW.data_dolaczenia < current_date OR
     CAST(SUBSTRING(NEW.PESEL, 10, 1) AS UNSIGNED) <>
     (MOD(9 * CAST(SUBSTRING(NEW.PESEL, 1, 1) AS UNSIGNED) +
          7 * CAST(SUBSTRING(NEW.PESEL, 2, 1) AS UNSIGNED) +
          3 * CAST(SUBSTRING(NEW.PESEL, 3, 1) AS UNSIGNED) +
          1 * CAST(SUBSTRING(NEW.PESEL, 4, 1) AS UNSIGNED) +
          9 * CAST(SUBSTRING(NEW.PESEL, 5, 1) AS UNSIGNED) +
          7 * CAST(SUBSTRING(NEW.PESEL, 6, 1) AS UNSIGNED) +
          3 * CAST(SUBSTRING(NEW.PESEL, 7, 1) AS UNSIGNED) +
          1 * CAST(SUBSTRING(NEW.PESEL, 8, 1) AS UNSIGNED) +
          9 * CAST(SUBSTRING(NEW.PESEL, 9, 1) AS UNSIGNED) +
          7 * CAST(SUBSTRING(NEW.PESEL, 10, 1) AS UNSIGNED),
          10))
  THEN
    SIGNAL SQLSTATE '12345'
      SET MESSAGE_TEXT = 'nieprawidlowy pesel lub data dolaczenia';
  END IF;
END//
DELIMITER ;
