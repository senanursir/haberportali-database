--YORUM EKLEME PROSEDURU OLUSTURDUM
CREATE OR REPLACE PROCEDURE yorumekle(
    p_haber_id INT,
    p_kullanici_id INT,
    p_yorum TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO yorumlar(haber_id, kullanici_id, yorum, tarih)
    VALUES (p_haber_id, p_kullanici_id, p_yorum, CURRENT_DATE);
END;
$$;

CALL yorumekle(4, 2, 'dolar 33,5 olmuş, bu devirde bilgisayar alınmaz.');
CALL yorumekle(5, 6, 'Allah yar ve yardımcımız olsun');
CALL yorumekle(6, 20, 'Doncici olan kazanır abi.');
CALL yorumekle(6, 4, 'seri baya sardı.');
CALL yorumekle(4, 20, 'şaşırmadık.');
CALL yorumekle(4, 20, 'tek bir sebebi var...');
CALL yorumekle(7, 1, 'bi ben yoktum.');

CALL yorumekle(20, 2, 'tek basına Star.'); ---

select *from yorumlar
select * from haber
order by haber_id asc

------------------------------------------------------------------------------------------
--HABER EKLEME PROSEDURU(ROL KONTROLLU)
--
CREATE OR REPLACE PROCEDURE haberekle(
    p_kullanici_id INT,
    p_baslik varchar,
    p_icerik varchar,
    p_yazar_id INT,
    p_kategori_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    --Kullanıcının rolünü kontrol ettim.
    IF (SELECT roller FROM kullanici WHERE kullanici_id = p_kullanici_id) = false THEN
        RAISE EXCEPTION 'Bu kullanıcı haber ekleme iznine sahip değil.';
    ELSE
        --Haber tablosuna yeni satır ekledim.
        INSERT INTO haber ( kullanici_id,baslik, icerik, yazar_id, kategori_id, tarih, guncelleme)
        VALUES ( p_kullanici_id,p_baslik, p_icerik, p_yazar_id, p_kategori_id, CURRENT_DATE, CURRENT_DATE);
    END IF;
END;
$$;

select *from kullanici --
--true
CALL haberekle(5, 'Yeni Haber Başlığı', 'Haber İçeriği', 4, 2); ---

--false
CALL haberekle(2, 'Yeni Haber Başlığı', 'Haber İçeriği', 3, 5);---


-----------------------------------------------------------------------------

--REKLAM EKLEME PROSEDURU
--
CREATE OR REPLACE PROCEDURE reklam_ekle(
    p_reklam_baslik VARCHAR(100),
    p_reklam_aciklama varchar,
    p_zaman timestamp,
    p_goruntulenme_sayisi INT,
    p_haber_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_reklam_id INT;
BEGIN
    -- Reklamı eklemek için.
    INSERT INTO reklam (reklam_baslik, reklam_aciklama, zaman, goruntulenme_sayisi)
    VALUES (p_reklam_baslik, p_reklam_aciklama, p_zaman, p_goruntulenme_sayisi)
    RETURNING reklam_id INTO v_reklam_id;
    
    -- Reklamı habere ilişkilendirmek için.
    INSERT INTO haber_reklam (haber_id, reklam_id)
    VALUES (p_haber_id, v_reklam_id);
END;
$$;

CALL reklam_ekle(
    'Yeni Yıl Kampanyası', 
    'Büyük indirim fırsatları', 
    '2024-01-01', 
    0, 
    3
);

CALL reklam_ekle(
    'Yaz İndirimi', 
    'Yaz boyunca büyük fırsatlar', 
    '2024-06-01', 
    0, 
    5
);

CALL reklam_ekle(
    'Kış Fırsatları', 
    'Soğuk kış günlerinde sıcak indirimler', 
    '2024-12-01', 
    0, 
    6
);

CALL reklam_ekle(
    'Teknoloji Kampanyası', 
    'En yeni teknolojilerde büyük indirim', 
    '2024-05-26', 
    0, 
    4
);

CALL reklam_ekle(
    'Beyaz Eşya Kampanyası', 
    'Beyaz eşya ürünlerinde kaçırılmayacak fırsatlar', 
    '2024-11-25', 
    0, 
    5
);
CALL reklam_ekle(
    'Moda Haftası İndirimi', 
    'Yeni sezon moda ürünlerinde büyük indirim', 
    '2024-02-14', 
    0, 
    6
);

CALL reklam_ekle(
    'Süpermarket İndirimi', 
    'Gıda ve temizlik ürünlerinde büyük indirim', 
    '2024-04-12', 
    0, 
    7
);

CALL reklam_ekle(
    'Teknoloji Haftası', 
    'Teknolojik ürünlerde dev fırsatlar', 
    '2024-08-05', 
    0, 
    19
);

CALL reklam_ekle(
    'Bahçe Mobilyaları Kampanyası', 
    'Yeni sezon bahçe mobilyalarında büyük indirim', 
    '2024-03-20', 
    0, 
    20
);

select * from reklam_detaylari;--

------------------------------------------------------------------
--REKLAM GORUNTULENME TABLO OLUŞTURMA
CREATE TABLE goruntuleme(
	goruntulenme_id serial PRIMARY KEY,
	reklam_id int REFERENCES reklam(reklam_id) not null,
	kullanici_id int references kullanici(kullanici_id) not null
)
--------------------------------------------------------------------------------------

--haber tablosuna kullanıcı sutunu ekledim.
ALTER TABLE haber
ADD CONSTRAINT fk_kullanici
FOREIGN KEY (kullanici_id) REFERENCES kullanici(kullanici_id);
--------------------------------------------------------------------------------------------
--BEGENİ TRİGGER (begeni_sayısı)

--trigger begeni sayısını saydı,begeni tablosuna sutun eklendikce haber tablosunda begeni_sayısı kısmında sayıldi.
ALTER TABLE "haber"
ADD COLUMN "begeni_sayisi" INT DEFAULT 0; --begeni sayısını saymak için sutun ekledim

-- Trigger fonksiyonunu oluşturdum
CREATE OR REPLACE FUNCTION update_begeni_sayisi()
RETURNS TRIGGER AS $$
BEGIN
    -- begeni_sayisini +1
    UPDATE "haber"
    SET "begeni_sayisi" = "begeni_sayisi" + 1
    WHERE "haber_id" = NEW.haber_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger'ı oluşturtum ve fonk. cagırdım
CREATE TRIGGER trigger_update_begeni_sayisi
AFTER INSERT ON "begeniler"
FOR EACH ROW
EXECUTE FUNCTION update_begeni_sayisi();

select * from haber  ---
order by haber_id asc
	
select *from begeniler; ----


--------------------------------------------------------------------------------------------

--YORUM TRİGGER (yorum_sayısı)
--yorum sayısı arttıkca haber tablosundan begeni takip edilir.
ALTER TABLE "haber"
ADD COLUMN "yorum_sayisi" INT DEFAULT 0; --begeni sayısını saymak için sutun ekledim

-- Trigger fonksiyonunu oluşturdum
CREATE OR REPLACE FUNCTION update_yorum_sayisi()
RETURNS TRIGGER AS $$
BEGIN
    
    UPDATE "haber"
    SET "yorum_sayisi" = "yorum_sayisi" + 1
    WHERE "haber_id" = NEW.haber_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger'ı oluşturtum ve fonk. cagırdım
CREATE TRIGGER trigger_update_yorum_sayisi
AFTER INSERT ON "yorumlar"
FOR EACH ROW
EXECUTE FUNCTION update_yorum_sayisi();




------------------------------------------------------------------------------------------

--KATEGORİLERE GÖRE HABER SAYILARI
--SKALER DEĞER DÖNDÜREN FONKSİYONUM.
CREATE OR REPLACE FUNCTION kategori_sayac(p_kategori_id INT)
RETURNS INT AS $$
DECLARE
    haber_sayisi INT;
BEGIN
    SELECT COUNT(*)
    INTO haber_sayisi
    FROM haber
    WHERE kategori_id = p_kategori_id;
    
    RETURN haber_sayisi;
END;
$$ LANGUAGE plpgsql;

SELECT kategori_sayac(5);

CREATE TABLE reklam(
	reklam_id SERIAL PRIMARY KEY,
    reklam_baslik VARCHAR(100) NOT NULL,
    reklam_aciklama varchar(50),
    zaman TIMESTAMP NOT NULL,
    goruntulenme_sayisi INT DEFAULT 0
	)

CREATE TABLE haber_reklam (
    haber_id INT,
    reklam_id INT,
    PRIMARY KEY (haber_id, reklam_id),
    FOREIGN KEY (haber_id) REFERENCES haber(haber_id) ON DELETE CASCADE,
    FOREIGN KEY (reklam_id) REFERENCES reklam(reklam_id) ON DELETE CASCADE
);

/*INSERT INTO reklam (reklam_baslik, reklam_aciklama, zaman, goruntulenme_sayisi)
VALUES ('enfes akışkan çikolatasıyla albeni raflarda', 'çikolata', '2024-05-26', 0);

INSERT INTO haber_reklam (haber_id, reklam_id)
VALUES (3, 1);*/

select * from kategoriler;
select *from kategori_sayac(5);--
select *from kategori_sayac(4);--

select *from haber
--------------------------------------------------------------------------------------------
--YORUM SAYISI TRİGGER
--yorum yapıldıkça haber tablosunda yorum_sayısında tutar.
	
-- Trigger fonksiyonunu oluşturdum
CREATE OR REPLACE FUNCTION update_yorum_sayisi()
RETURNS TRIGGER AS $$
BEGIN
	
    UPDATE "haber"
    SET "yorum_sayisi" = "yorum_sayisi" + 1
    WHERE "haber_id" = NEW.haber_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger'ı oluşturtum ve fonk. cagırdım
CREATE TRIGGER trigger_update_yorum_sayisi
AFTER INSERT ON "yorumlar"
FOR EACH ROW
EXECUTE FUNCTION update_yorum_sayisi();


------------------------------------------------------------------------------------------

--YORUM VE KULLANICI ÖZELLİKLERİNİ TABLO OLARAK DÖNDÜREN FONKSİYON
CREATE OR REPLACE FUNCTION yorumlari_getir()
RETURNS TABLE (
    kullanici_id INT,
    kullaniciadi VARCHAR(15),
    adsoyad TEXT,
    baslik VARCHAR,
    yorum VARCHAR,
    tarih DATE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        k.kullanici_id,
        k.kullaniciadi,
        CONCAT(k.ad, ' ', k.soyad) AS adsoyad, --Ad ve soyad birlesti
        h.baslik,
        y.yorum,
        y.tarih
    FROM 
        kullanici k
    JOIN 
        yorumlar y
    ON 
        k.kullanici_id = y.kullanici_id
    JOIN 
        haber h
    ON 
        y.haber_id = h.haber_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM yorumlari_getir()
order by kullanici_id  asc

------------------------------------------------------------------------------------------


--rol sutunu eklendi
/*ALTER TABLE kullanici
ADD COLUMN roller BOOLEAN NOT NULL DEFAULT FALSE;*/

------------------------------------------------------------------------------------------


--GÖRÜNTÜLENME SAYISINI OTOMATİK ARTIRAN TRİGGER---
--
CREATE OR REPLACE FUNCTION goruntulenme_sayisi_tg()
RETURNS TRIGGER AS $$
BEGIN
    -- reklam tablosundaki goruntulenme_sayisi değerini artır
    UPDATE reklam
    SET goruntulenme_sayisi = goruntulenme_sayisi + 1
    WHERE reklam_id = NEW.reklam_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER goruntulenme_ekle_trigger
AFTER INSERT ON reklam_goruntulenme
FOR EACH ROW
EXECUTE FUNCTION goruntulenme_sayisi_tg();

INSERT INTO reklam_goruntulenme (reklam_id, kullanici_id)
VALUES (1,19);

--ALTER TABLE goruntuleme RENAME TO reklam_goruntulenme;
----------------------------------------------------------------------------------------------
---reklam_goruntulemeye veri ekledim
INSERT INTO reklam_goruntulenme (reklam_id, kullanici_id)
VALUES 
    (1, 1),
    (1, 2),
    (1, 5),
    (3, 4),
    (4, 5),
    (5, 6),
    (6, 7),
    (6, 8),
    (8, 9),
    (9, 10),
    (10, 11),
    (11, 12),
    (12, 13),
    (1, 14),
    (1, 15),
    (3, 16),
    (4, 17),
    (5, 18),
    (6, 19),
    (8, 20);
------------------------------------------------------------------------------------------
--ETİKET ATAYAN VE TABLO DÖNDÜREN VİEW
--BEĞENİ SAYISINA GÖRE HABERİN ETİKETİNİ ATAR 
CREATE OR REPLACE VIEW haber_etiketleri AS
SELECT
    h.haber_id,
    h.baslik,
    h.icerik,
    h.tarih,
    CASE
        WHEN h.begeni_sayisi > 10 THEN 1
        WHEN h.begeni_sayisi BETWEEN 5 AND 10 THEN 2
        ELSE 3
    END AS etiket_id,
    e.adi AS etiket_adi
FROM
    haber h
LEFT JOIN
    etiketler e
ON
    e.etiket_id = CASE
                    WHEN h.begeni_sayisi > 10 THEN 1
                    WHEN h.begeni_sayisi BETWEEN 5 AND 10 THEN 2
                    ELSE 3
                  END;

select * from etiketler --
select * from haber_etiketleri

------------------------------------------------------------------------------------------

--HABERDETAY VİEW
--
CREATE OR REPLACE VIEW haber_detaylari AS
SELECT
    h.haber_id,
    h.baslik,
    CONCAT(k.ad, ' ', k.soyad) AS yazar_adi, --AD SOYAD BİRLESTİ
    y.yazar_id,
    yo.yorum,
    g.url,
    h.begeni_sayisi
FROM
    haber h
JOIN
    yazar y ON h.yazar_id = y.yazar_id
JOIN
    kullanici k ON y.kullanici_id = k.kullanici_id
LEFT JOIN
    yorumlar yo ON h.haber_id = yo.haber_id
LEFT JOIN
    gorseller g ON h.haber_id = g.haber_id;


select * from haber_detaylari; ----


/*
-- 'ad' sütununu 'isim' olarak değiştirme
ALTER TABLE kullanici RENAME COLUMN adi TO soyad;

-- 'soyad' sütununu 'soyisim' olarak değiştirme
ALTER TABLE kullanici RENAME COLUMN soyadi TO ad;
*/

-----------------------------------------------------------------------------------------
--REKLAM VİEW
-----
CREATE OR REPLACE VIEW reklam_detaylari AS
SELECT 
    h.baslik AS hedef_baslik,
	k.kategori_id,
    r.reklam_baslik,
    r.zaman,
    r.goruntulenme_sayisi
FROM 
    haber h
JOIN 
    kategoriler k ON h.kategori_id = k.kategori_id
JOIN 
    haber_reklam hr ON h.haber_id = hr.haber_id
JOIN 
    reklam r ON hr.reklam_id = r.reklam_id;


SELECT * FROM reklam_detaylari;


-------------------------------------------------------------


----SORGULAR----- 

-- Tüm haberleri listele
SELECT * FROM haber;

-- Belirli bir yazara ait haberleri listele
SELECT * FROM haber WHERE yazar_id = 2;

-- Yeni bir haber ekle
INSERT INTO haber (baslik, icerik, yazar_id, kategori_id, tarih, guncelleme, begeni_sayisi, yorum_sayisi, kullanici_id)
VALUES ('O Eser Açık Artırmaya Çıktı!', 'Ünlü Tablo', 8, 1, , CURRENT_DATE, CURRENT_DATE, 0, 0, 17);

-- Yeni bir kullanıcı ekle
INSERT INTO kullanici (kullaniciadi, eposta, sifre, kayittarihi, ad, soyad, roller)
VALUES ('Ceren', 'godere@gmail.com', 'ciren', CURRENT_DATE, 'Ceren', 'Özbek', false);

-- Belirli bir haberin başlığını güncelle
UPDATE haber
SET baslik = 'Güncellenmiş Haber Başlığı'
WHERE haber_id = 3;

-- Kullanıcı rolünü güncelle
UPDATE kullanici
SET roller = true
WHERE kullanici_id = 1;

select *from kullanici--
order by kullanici_id
	
-- Belirli bir haberi sil
DELETE FROM haber
WHERE haber_id = 3;

select * from haber--
order by haber_id
	
-- Belirli bir kullanıcıyı sil
DELETE FROM kullanici
WHERE kullanici_id = 1;

select *from kullanici--
order by kullanici_id
	
-- Tüm haberleri beğeni sayısına göre azalan sırada listele --

SELECT * FROM haber
ORDER BY begeni_sayisi DESC;

-- Her haberin başlığı ve yazarın adı ile soyadını listele --
SELECT h.baslik, k.ad, k.soyad
FROM haber h
JOIN yazar y ON h.yazar_id = y.yazar_id
JOIN kullanici k ON y.kullanici_id = k.kullanici_id;

-- Belirli bir kategorideki haberleri listele
SELECT * FROM haber
WHERE kategori_id = 2;

-- Belirli bir tarihten sonraki haberleri listele --
SELECT * FROM haber
WHERE tarih > '2024-05-25';

-- Başlığında 'Kampanyası' kelimesi geçen reklamları listele --
SELECT * FROM reklam
WHERE reklam_baslik LIKE '%Kampanyası%';

-- Kullanıcı adında 's' geçen kullanıcıları listele
SELECT * FROM kullanici
WHERE kullaniciadi LIKE '%s%';

-- acıklamasında 'fırsat' kelimesi geçen reklamları listele
SELECT * FROM reklam
WHERE reklam_aciklama LIKE '%fırsat%'
ORDER BY reklam_id;

-- Kullanıcı adında '1' geçen kullanıcıları listele
SELECT * FROM kullanici
WHERE kullaniciadi LIKE '%1%';


--EN YÜKSEK BEĞENİ SAYISINA SAHİP OLAN HABER --
SELECT * FROM haber
WHERE begeni_sayisi = (SELECT MAX(begeni_sayisi) FROM haber);

--EN DÜŞÜK BEĞENİ SAYISINA SAHİP OLAN HABER
SELECT * FROM haber
WHERE begeni_sayisi = (SELECT MIN(begeni_sayisi) FROM haber);

---TOPLAM BEĞENİ SAYISI
SELECT SUM(begeni_sayisi) AS toplam_begeni_sayisi FROM haber;

----TOPLAM YORUM SAYISI
SELECT SUM(yorum_sayisi) AS toplam_yorum_sayisi FROM haber;
