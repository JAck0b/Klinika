create database Klinika default character set utf8 collate utf8_unicode_ci;

create table uzytkownicy
(
  PESEL           char(11)                               not null primary key,
  imie            varchar(30)                            not null,
  nazwisko        varchar(30)                            not null,
  data_dolaczenia date                                   not null,
  rola            enum ('Prezes', 'Pracownik', 'Klient') not null comment 'Trzy podstawowe rodzaje uzytkownikow.'
);

create table uprawnienia
(
  ID    int         not null primary key auto_increment,
  nazwa varchar(45) not null
);

create table uslugi_rehabilitacyjne
(
  ID           int          not null primary key auto_increment,
  rodzaj       varchar(50)  not null,
  nazwa        varchar(100) not null,
  czas_trwania int          not null,
  cena         int          not null,
  uprawnienia  int          not null,
  constraint uprawnieniaU
    foreign key (uprawnienia)
      references uprawnienia (ID)
      on update no action
      on delete no action
);

create table transakcje
(
  ID       int                                           not null primary key auto_increment,
  odbiorca char(11)                                      not null,
  constraint odbiorcaT
    foreign key (odbiorca)
      references uzytkownicy (PESEL)
      on update no action
      on delete no action,
  placacy  char(11)                                      not null,
  constraint placacyT
    foreign key (placacy)
      references uzytkownicy (PESEL)
      on update no action
      on delete no action,
  data     date                                          not null,
  kwota    int                                           not null,
  opis     enum ('pensja', 'za_zabieg', 'zwrot', 'inne') not null
);

create table stanowiska
(
  ID             int         not null primary key auto_increment,
  nazwa          varchar(45) not null,
  max_ilosc_osob int         not null
);

create table zabiegi
(
  ID           int      not null primary key auto_increment,
  klient       char(11) not null,
  constraint klientZ
    foreign key (klient)
      references uzytkownicy (PESEL)
      on update no action
      on delete no action,
  pracownik    char(11) not null,
  constraint pracownikZ
    foreign key (pracownik)
      references uzytkownicy (PESEL)
      on update no action
      on delete no action,
  data_zabiegu datetime not null,
  usluga       int      not null,
  constraint uslugaZ
    foreign key (usluga)
      references uslugi_rehabilitacyjne (ID)
      on update no action
      on delete no action,
  stanowisko   int      not null,
  constraint stanowiskoZ
    foreign key (stanowisko)
      references stanowiska (ID)
      on update no action
      on delete no action

);

create table stan_konta
(
  uzytkownik char(11) not null,
  constraint uzytkownikS
    foreign key (uzytkownik)
      references uzytkownicy (PESEL)
      on update no action
      on delete no action,
  saldo      int      not null
);

create table specjalizacje
(
  uzytkownik  char(11) not null,
  constraint uzytkownikSp
    foreign key (uzytkownik)
      references uzytkownicy (PESEL)
      on update no action
      on delete no action,
  uprawnienia int      not null,
  constraint uprawnieniaSp
    foreign key (uprawnienia)
      references uprawnienia (ID)
      on update no action
      on delete no action
);


create table dokumentacja
(
  data                      datetime     not null primary key,
  nazwa_obiektu_testowanego varchar(50)  not null,
  czas                      int          not null comment 'Czas jest podawany w sekundach.',
  ilosc_rekodrow            int          not null,
  comentarz                 varchar(100) not null
);

create table dostep_do_stanowiska
(
  stanowisko           varchar(45) not null,
  wymagane_uprawnienia int         not null,
  constraint wymagane_uprawnieniaD
    foreign key (wymagane_uprawnienia)
      references uprawnienia (ID)
      on update no action
      on delete no action
);

create table godziny_otwarcia
(
  ID int not null primary key,
  nazwa varchar(15) not null,
  godzina_rozpoczecia time not null,
  godzina_zaczonczenia time not null
);

insert into godziny_otwarcia (ID, nazwa, godzina_rozpoczecia, godzina_zaczonczenia)
VALUES (0, 'Niedziela', '08:00:00', '16:00:00'),
       (1, 'Poniedzialek', '08:00:00', '16:00:00'),
       (2, 'Wtorek', '08:00:00', '16:00:00'),
       (3, 'Sroda', '08:00:00', '16:00:00'),
       (4, 'Czwartek', '08:00:00', '16:00:00'),
       (5, 'Piatek', '08:00:00', '16:00:00'),
       (6, 'Sobota', '08:00:00', '16:00:00');


DROP PROCEDURE IF EXISTS dodajuser;
DELIMITER //
CREATE PROCEDURE dodajuser(IN ilosc INT, IN iloscklientow INT) #ilosc pracownikow = ilosc - iloscklientow - 1 (bo prezez)
BEGIN
  DECLARE i INT DEFAULT 0; #iterator po ilosci
  DECLARE j INT DEFAULT 0; #iterator po peselach w tym samym dniu
  DECLARE tesamedaty INT; #zmienna losowa odpowiasajaca za
  DECLARE rozmedaty INT DEFAULT 0; #diffeerent date
  DECLARE mindata DATE DEFAULT '2010-12-31'; #urodziny na
  DECLARE data DATE;
  DECLARE peselbezkontrolnej char(10);
  WHILE i < ilosc DO
  SET j = 0;
  SET data = DATE_SUB(mindata, INTERVAL rozmedaty DAY);
  SET tesamedaty = FLOOR(RAND() * 100 + 1);
  WHILE j < tesamedaty DO
  SET peselbezkontrolnej = CONCAT(
      SUBSTRING(YEAR(data), 3, 2),
      IF(YEAR(data) < 2000,
         LPAD(MONTH(data), 2, "0"),
         LPAD(MONTH(data) + 20, 2, "0")),
      LPAD(DAYOFMONTH(data), 2, "0"),
      cast((9999 - j) as char(4))
    );

  INSERT INTO uzytkownicy (PESEL, imie, nazwisko, data_dolaczenia, rola)
  VALUES (CONCAT(peselbezkontrolnej,
                 MOD(9 * CAST(SUBSTRING(peselbezkontrolnej, 1, 1) AS UNSIGNED) +
                     7 * CAST(SUBSTRING(peselbezkontrolnej, 2, 1) AS UNSIGNED) +
                     3 * CAST(SUBSTRING(peselbezkontrolnej, 3, 1) AS UNSIGNED) +
                     1 * CAST(SUBSTRING(peselbezkontrolnej, 4, 1) AS UNSIGNED) +
                     9 * CAST(SUBSTRING(peselbezkontrolnej, 5, 1) AS UNSIGNED) +
                     7 * CAST(SUBSTRING(peselbezkontrolnej, 6, 1) AS UNSIGNED) +
                     3 * CAST(SUBSTRING(peselbezkontrolnej, 7, 1) AS UNSIGNED) +
                     1 * CAST(SUBSTRING(peselbezkontrolnej, 8, 1) AS UNSIGNED) +
                     9 * CAST(SUBSTRING(peselbezkontrolnej, 9, 1) AS UNSIGNED) +
                     7 * CAST(SUBSTRING(peselbezkontrolnej, 10, 1) AS UNSIGNED),
                     10)),
          ELT(FLOOR(RAND() * 624 + 1), 'Ada', 'Adalbert', 'Adam', 'Adela', 'Adelajda', 'Adrian', 'Aga', 'Agata',
              'Agnieszka', 'Albert', 'Alberta', 'Aldona', 'Aleksander', 'Aleksandra', 'Alfred', 'Alicja', 'Alina',
              'Amadeusz', 'Ambrozy', 'Amelia', 'Anastazja', 'Anastazy', 'Anatol', 'Andrzej', 'Aneta', 'Angelika',
              'Angelina', 'Aniela', 'Anita', 'Anna', 'Antoni', 'Antonina', 'Anzelm', 'Apolinary', 'Apollo', 'Apolonia',
              'Apoloniusz', 'Ariadna', 'Arkadiusz', 'Arkady', 'Arlena', 'Arleta', 'Arletta', 'Arnold', 'Arnolf',
              'August', 'Augustyna', 'Aurela', 'Aurelia', 'Aurelian', 'Aureliusz', 'Balbina', 'Baltazar', 'Barbara',
              'Bartlomiej', 'Bartosz', 'Bazyli', 'Beata', 'Benedykt', 'Benedykta', 'Beniamin', 'Bernadeta', 'Bernard',
              'Bernardeta', 'Bernardyn', 'Bernardyna', 'Blazej', 'Bogdan', 'Bogdana', 'Bogna', 'Bogumil', 'Bogumila',
              'Boguslaw', 'Boguslawa', 'Bohdan', 'Boleslaw', 'Bonawentura', 'Bozena', 'Bronislaw', 'Broniszlaw',
              'Bronislawa', 'Brunon', 'Brygida', 'Cecyl', 'Cecylia', 'Celestyn', 'Celestyna', 'Celina', 'Cezary',
              'Cyprian', 'Cyryl', 'Dalia', 'Damian', 'Daniel', 'Daniela', 'Danuta', 'Daria', 'Dariusz', 'Dawid',
              'Diana', 'Dianna', 'Dobrawa', 'Dominik', 'Dominika', 'Donata', 'Dorian', 'Dorota', 'Dymitr', 'Edmund',
              'Edward', 'Edwin', 'Edyta', 'Egon', 'Eleonora', 'Eliasz', 'Eligiusz', 'Eliza', 'Elwira', 'Elzbieta',
              'Emanuel', 'Emanuela', 'Emil', 'Emilia', 'Emilian', 'Emiliana', 'Ernest', 'Ernestyna', 'Erwin', 'Erwina',
              'Eryk', 'Eryka', 'Eugenia', 'Eugeniusz', 'Eulalia', 'Eustachy', 'Ewelina', 'Fabian', 'Faustyn',
              'Faustyna', 'Felicja', 'Felicjan', 'Felicyta', 'Feliks', 'Ferdynand', 'Filip', 'Franciszek', 'Salezy',
              'Franciszka', 'Fryderyk', 'Fryderyka', 'Gabriel', 'Gabriela', 'Gawel', 'Genowefa', 'Gerard', 'Gerarda',
              'Gerhard', 'Gertruda', 'Gerwazy', 'Godfryd', 'Gracja', 'Gracjan', 'Grazyna', 'Greta', 'Grzegorz',
              'Gustaw', 'Gustawa', 'Gwidon', 'Halina', 'Hanna', 'Helena', 'Henryk', 'Henryka', 'Herbert', 'Hieronim',
              'Hilary', 'Hipolit', 'Honorata', 'Hubert', 'Ida', 'Idalia', 'Idzi', 'Iga', 'Ignacy', 'Igor', 'Ildefons',
              'Ilona', 'Inga', 'Ingeborga', 'Irena', 'Ireneusz', 'Irma', 'Irmina', 'Irwin', 'Ismena', 'Iwo', 'Iwona',
              'Izabela', 'Izolda', 'Izyda', 'Izydor', 'Jacek', 'Jadwiga', 'Jagoda', 'Jakub', 'Jan', 'Janina', 'January',
              'Janusz', 'Jarema', 'Jarogniew', 'Jaromir', 'Jaroslaw', 'Jaroslawa', 'Jeremi', 'Jeremiasz', 'Jerzy',
              'Jedrzej', 'Joachim', 'Joanna', 'Jolanta', 'Jonasz', 'Jonatan', 'Jowita', 'Jozef', 'Jozefa', 'Jozefina',
              'Judyta', 'Julia', 'Julian', 'Julianna', 'Julita', 'Juliusz', 'Justyn', 'Justyna', 'Kacper', 'Kaja',
              'Kajetan', 'Kalina', 'Kamil', 'Kamila', 'Karina', 'Karol', 'Karolina', 'Kasper', 'Katarzyna', 'Kazimiera',
              'Kazimierz', 'Kinga', 'Klara', 'Klarysa', 'Klaudia', 'Klaudiusz', 'Klaudyna', 'Klemens', 'Klementyn',
              'Klementyna', 'Kleopatra', 'Klotylda', 'Konrad', 'Konrada', 'Konstancja', 'Konstanty', 'Konstantyn',
              'Kordelia', 'Kordian', 'Kordula', 'Kornel', 'Kornelia', 'Kryspin', 'Krystian', 'Krystyn', 'Krystyna',
              'Krzysztof', 'Ksenia', 'Kunegunda', 'Laura', 'Laurenty', 'Laurentyn', 'Laurentyna', 'Lech', 'Lechoslaw',
              'Lechoslawa', 'Leokadia', 'Leon', 'Leonard', 'Leonarda', 'Leonia', 'Leopold', 'Leopoldyna', 'Leslaw',
              'Leslawa', 'Leszek', 'Lidia', 'Ligia', 'Lilian', 'Liliana', 'Lilianna', 'Lilla', 'Liwia', 'Liwiusz',
              'Liza', 'Lolita', 'Longin', 'Loretta', 'Luba', 'Lubomir', 'Lubomira', 'Lucja', 'Lucjan', 'Lucjusz',
              'Lucyna', 'Ludmila', 'Ludomil', 'Ludomir', 'Ludoslaw', 'Ludwik', 'Ludwika', 'Ludwina', 'Luiza',
              'Lukrecja', 'Lutoslaw', 'Lucja', 'Lucjan', 'Lukasz', 'Maciej', 'Madlena', 'Magda', 'Magdalena', 'Makary',
              'Maksym', 'Maksymilian', 'Malina', 'Malwin', 'Malwina', 'Malgorzata', 'Manfred', 'Manfreda', 'Manuela',
              'Marcel', 'Marcela', 'Marceli', 'Marcelina', 'Marcin', 'Marcjan', 'Marcjanna', 'Marcjusz', 'Marek',
              'Margareta', 'Maria', 'MariaMagdalena', 'Marian', 'Marianna', 'Marietta', 'Marina', 'Mariola', 'Mariusz',
              'Marlena', 'Marta', 'Martyna', 'Maryla', 'Maryna', 'Marzanna', 'Marzena', 'Mateusz', 'Matylda', 'Maurycy',
              'Melania', 'Melchior', 'Metody', 'Michalina', 'Michal', 'Mieczyslaw', 'Mieczyslawa', 'Mieszko', 'Mikolaj',
              'Milena', 'Mila', 'Milosz', 'Milowan', 'Milowit', 'Mira', 'Mirabella', 'Mirella', 'Miron', 'Miroslaw',
              'Miroslawa', 'Modest', 'Monika', 'Nadia', 'Nadzieja', 'Napoleon', 'Narcyz', 'Narcyza', 'Nastazja',
              'Natalia', 'Natasza', 'Nikita', 'Nikodem', 'Nina', 'Nora', 'Norbert', 'Norberta', 'Norma', 'Norman',
              'Oda', 'Odila', 'Odon', 'Ofelia', 'Oksana', 'Oktawia', 'Oktawian', 'Olaf', 'Oleg', 'Olga', 'Olgierd',
              'Olimpia', 'Oliwia', 'Oliwier', 'Onufry', 'Orfeusz', 'Oskar', 'Otto', 'Otylia', 'Pankracy', 'Parys',
              'Patrycja', 'Patrycy', 'Patryk', 'Paula', 'Paulina', 'Pawel', 'Pelagia', 'Petronela', 'Petronia',
              'Petroniusz', 'Piotr', 'Pola', 'Polikarp', 'Protazy', 'Przemyslaw', 'Radomil', 'Radomila', 'Radomir',
              'Radoslaw', 'Radoslawa', 'Radzimir', 'Rafael', 'Rafaela', 'Rafal', 'Rajmund', 'Rajmunda', 'Rajnold',
              'Rebeka', 'Regina', 'Remigiusz', 'Rena', 'Renata', 'Robert', 'Roberta', 'Roch', 'Roderyk', 'Rodryg',
              'Rodryk', 'Roger', 'Roksana', 'Roland', 'Roma', 'Roman', 'Romana', 'Romeo', 'Romuald', 'Rozalia',
              'Rozanna', 'Roza', 'Rudolf', 'Rudolfa', 'Rudolfina', 'Rufin', 'Rupert', 'Ryszard', 'Ryszarda', 'Sabina',
              'Salomea', 'Salomon', 'Samuel', 'Samuela', 'Sandra', 'Sara', 'Sawa', 'Sebastian', 'Serafin', 'Sergiusz',
              'Sewer', 'Seweryn', 'Seweryna', 'Sedzislaw', 'Sedziwoj', 'Siemowit', 'Slawa', 'Slawomir', 'Slawomira',
              'Slawosz', 'Sobieslaw', 'Sobieslawa', 'Sofia', 'Sonia', 'Stanislaw', 'Stanislawa', 'Stefan', 'Stefania',
              'Sulimiera', 'Sulimierz', 'Sulimir', 'Sydonia', 'Sykstus', 'Sylwan', 'Sylwana', 'Sylwester', 'Sylwia',
              'Sylwiusz', 'Symeon', 'Szczepan', 'Szczesna', 'Szczesny', 'Szymon', 'Scibor', 'Swietopelk', 'Tadeusz',
              'Tamara', 'Tatiana', 'Tekla', 'Telimena', 'Teodor', 'Teodora', 'Teodozja', 'Teodozjusz', 'Teofil',
              'Teofila', 'Teresa', 'Tobiasz', 'Toma', 'Tomasz', 'Tristan', 'Trojan', 'Tycjan', 'Tymon', 'Tymoteusz',
              'Tytus', 'Unislaw', 'Ursyn', 'Urszula', 'Violetta', 'Waclaw', 'Waclawa', 'Waldemar', 'Walenty',
              'Walentyna', 'Waleria', 'Walerian', 'Waleriana', 'Walery', 'Walter', 'Wanda', 'Wasyl', 'Wawrzyniec',
              'Wera', 'Werner', 'Weronika', 'Wiezczysla', 'Wieslaw', 'Wieslawa', 'Wiktor', 'Wiktoria', 'Wilhelm',
              'Wilhelmina', 'Wilma', 'Wincenta', 'Wincenty', 'Wizczysla', 'Wiola', 'Wioletta', 'Wirgiliusz', 'Wirginia',
              'Wirginiusz', 'Wislaw', 'Wislawa', 'Wit', 'Witalis', 'Witold', 'Witolda', 'Witold', 'Witomir', 'Wiwanna',
              'Wladyslawa', 'Wladyslaw', 'Wlodzimierz', 'Wlodzimir', 'Wodzislaw', 'Wojciech', 'Wojciecha', 'Zachariasz',
              'Zbigniew', 'Zbyslaw', 'Zbyszko', 'Zdobyslaw', 'Zdzislaw', 'Zdzislawa', 'Zenobia', 'Zenobiusz', 'Zenon',
              'Zenona', 'Ziemowit', 'Zofia', 'Zula', 'Zuzanna', 'Zygfryd', 'Zygmunt', 'Zyta', 'Zaklina', 'Zaneta',
              'Zanna', 'Zelislaw', 'Zytomir'),
          ELT(FLOOR(RAND() * 94 + 1), 'Nowak', 'Kowalski', 'Wisniewski', 'Dabrowski', 'Lewandowski', 'Wojcik',
              'Kamizski', 'Kowalczyk', 'Zielizski', 'Szymazski', 'Wozniak', 'Kozlowski', 'Jankowski', 'Wojciechowski',
              'Kwiatkowski', 'Kaczmarek', 'Mazur', 'Krawczyk', 'Piotrowski', 'Grabowski', 'Nowakowski', 'Pawlowski',
              'Michalski', 'Nowicki', 'Adamczyk', 'Dudek', 'Zajac', 'Wieczorek', 'Jablozski', 'Krol', 'Majewski',
              'Olszewski', 'Jaworski', 'Wrobel', 'Malinowski', 'Pawlak', 'Witkowski', 'Walczak', 'Stepiez', 'Gorski',
              'Rutkowski', 'Michalak', 'Sikora', 'Ostrowski', 'Baran', 'Duda', 'Szewczyk', 'Tomaszewski', 'Pietrzak',
              'Marciniak', 'Wroblewski', 'Zalewski', 'Jakubowski', 'Jasizski', 'Zawadzki', 'Sadowski', 'Bak',
              'Chmielewski', 'Wlodarczyk', 'Borkowski', 'Czarnecki', 'Sawicki', 'Sokolowski', 'Urbazski', 'Kubiak',
              'Maciejewski', 'Szczepazski', 'Kucharski', 'Wilk', 'Kalinowski', 'Lis', 'Mazurek', 'Wysocki', 'Adamski',
              'Kazmierczak', 'Wasilewski', 'Sobczak', 'Czerwizski', 'Andrzejewski', 'Cieslak', 'Glowacki', 'Zakrzewski',
              'Kolodziej', 'Sikorski', 'Krajewski', 'Gajewski', 'Szymczak', 'Szulc', 'Baranowski', 'Laskowski',
              'Brzezizski', 'Makowski', 'Ziolkowski', 'Przybylski'),
          DATE_SUB(CURRENT_DATE, INTERVAL FLOOR(RAND() * 4000 + 1) DAY),
          IF(i < iloscklientow, 'Pracownik', 'Klient '));
  SET i = i + 1;
  SET j = j + 1;
  END WHILE;
  SET rozmedaty = rozmedaty + FLOOR(RAND() * 200);
  END WHILE;
END//
DELIMITER ;
-- CALL dodajuser(500,200);
