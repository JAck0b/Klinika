-- Tutaj są kody wszystkich procedur
# To nie jest jeszcze gotowa funkcja. Musi poczekać na swoją kolej.
delimiter //
create procedure wolne_terminy_zabiegu(in data date, in naz varchar(100), in rodz varchar(50))
begin
  declare iterator1 int default 0;
  declare warunek boolean default 0;
  declare ilosc int default 4 * timediff(select
                                         godziny_otwarcia.godzina_rozpoczecia # obliczanie ile jest kwadransów w godzinach pracy
                                         from godziny_otwarcia
                                         where godzina_rozpoczecia.ID = dayofweek(data) limit 1, select
                                         godziny_otwarcia.godzina_zakonczenia
                                         from godziny_otwarcia
                                         where godzina_rozpoczecia.ID = dayofweek(data) limit 1);
  declare czas time;
  declare czas_pomoc time;
  declare koniec int default true;
  declare pracownik_pomoc char(11);
  declare id_uslugi int;
  declare iterator cursor for select uzytkownicy.PESEL
                              from uzytkownicy
                                     join specjalizacje s on uzytkownicy.PESEL = s.uzytkownik
                                     join uprawnienia u on s.uprawnienia = u.nazwa
                                     join uslugi_rehabilitacyjne ur on u.nazwa = ur.uprawnienia
                              where ur.nazwa like naz
                                and ur.rodzaj like rodz;
  declare continue handler for not found set koniec = false;

  # ustalanie id danej usługi
  select ID
  from uslugi_rehabilitacyjne
  where nazwa like naz
    and rodzaj like rodz
  limit 1
    into id_uslugi;

  # można zmienić na wyszukiwanie dla każdego pracownika osobno
  create temporary table zabiegi_pomoc
  select *
  from zabiegi
  where usluga = id_uslugi
    and data_zabiegu like data;

  # ustalanie godziny rozpoczecia pracy kliniki w danym dniu
  select godziny_otwarcia.godzina_rozpoczecia
  from godziny_otwarcia
  where godzina_rozpoczecia.ID = dayofweek(data) # dobra godzina
        into czas;


  open iterator;
  fetch iterator into pracownik_pomoc;
  while koniec <> true do # przejście po wszystkich pracownikach, którzy spełniają warunki

  set czas_pomoc = czas;
    set iterator1 = 0;
    while iterator1 < ilosc do # przejście po wszystkich godzinach

      set warunek = if ();


      set iterator1 = iterator1 + 1;
      set czas_pomoc = addtime(czas_pomoc, '15:00');
    end while ;

    fetch iterator into pracownik_pomoc;
  end while;
  close iterator;
end //
delimiter ;
