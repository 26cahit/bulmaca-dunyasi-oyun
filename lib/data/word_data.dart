class WordItem {
  final String word;
  final String category;
  final String hint;
  final String info;

  const WordItem({
    required this.word,
    required this.category,
    required this.hint,
    required this.info,
  });
}

class WordData {
  static const List<WordItem> easyWords = [
    WordItem(
      word: "ELMA",
      category: "Meyve",
      hint: "Tatlı ve sulu bir meyvedir.",
      info: "Elma dünyada en çok tüketilen meyvelerden biridir.",
    ),

    WordItem(
      word: "ARMUT",
      category: "Meyve",
      hint: "İnce saplı, tatlı ve sulu bir meyvedir.",
      info: "Armut lif bakımından oldukça zengindir.",
    ),

    WordItem(
      word: "KEDİ",
      category: "Hayvan",
      hint: "Evlerde sıkça beslenen sevimli bir canlıdır.",
      info:
          "Kediler yaklaşık 9500 yıldır insanlar tarafından evcilleştirilmektedir.",
    ),

    WordItem(
      word: "KALEM",
      category: "Kırtasiye",
      hint: "Yazı yazmak için kullanılır.",
      info: "İlk kurşun kalemler 1500'lü yıllarda kullanılmaya başlanmıştır.",
    ),

    WordItem(
      word: "MASA",
      category: "Mobilya",
      hint: "Üzerinde yemek yenir veya ders çalışılır.",
      info: "Masalar farklı amaçlar için çeşitli boyutlarda üretilir.",
    ),

    WordItem(
      word: "SANDALYE",
      category: "Mobilya",
      hint: "Üzerine oturulan ev eşyasıdır.",
      info: "Sandalye, en yaygın kullanılan mobilyalardan biridir.",
    ),

    WordItem(
      word: "KİTAP",
      category: "Eğitim",
      hint: "Bilgi edinmek veya hikâye okumak için kullanılır.",
      info: "Dünyada milyonlarca farklı kitap bulunmaktadır.",
    ),

    WordItem(
      word: "DEFTER",
      category: "Kırtasiye",
      hint: "Yazı yazmak ve not almak için kullanılır.",
      info: "Defterler okul hayatının vazgeçilmez araçlarındandır.",
    ),

    WordItem(
      word: "OKUL",
      category: "Eğitim",
      hint: "Öğrencilerin eğitim aldığı yerdir.",
      info: "İlk modern okullar yüzlerce yıl önce kurulmuştur.",
    ),

    WordItem(
      word: "ÖĞRETMEN",
      category: "Meslek",
      hint: "Öğrencilere ders anlatan kişidir.",
      info: "Öğretmenlik dünyanın en saygın mesleklerinden biridir.",
    ),
  ];

  static const List<WordItem> mediumWords = [
    WordItem(
      word: "BİLGİSAYAR",
      category: "Teknoloji",
      hint: "İnternete girmek ve program çalıştırmak için kullanılır.",
      info: "İlk elektronik bilgisayarlar oda büyüklüğündeydi.",
    ),

    WordItem(
      word: "TELEFON",
      category: "Teknoloji",
      hint: "İnsanlarla konuşmamızı sağlayan elektronik cihazdır.",
      info: "Akıllı telefonlar aslında küçük bir bilgisayardır.",
    ),

    WordItem(
      word: "YAZILIM",
      category: "Bilişim",
      hint: "Programların tamamına verilen genel isimdir.",
      info: "Flutter ile geliştirilen uygulamalar da bir yazılımdır.",
    ),

    WordItem(
      word: "PROGRAM",
      category: "Bilişim",
      hint: "Bilgisayara ne yapacağını söyleyen komutlar bütünüdür.",
      info: "Her uygulama aslında bir programdır.",
    ),

    WordItem(
      word: "MANTIK",
      category: "Düşünme",
      hint: "Doğru çıkarımlar yapmayı sağlayan düşünme biçimidir.",
      info: "Mantık matematik ve bilgisayar bilimlerinde çok önemlidir.",
    ),

    WordItem(
      word: "BULMACA",
      category: "Oyun",
      hint: "Düşündürerek çözülen eğlenceli sorulardır.",
      info: "Bulmacalar hafızayı geliştirmeye yardımcı olur.",
    ),

    WordItem(
      word: "OYUNCU",
      category: "Meslek",
      hint: "Film veya tiyatroda rol alan kişidir.",
      info: "Oyuncular birçok farklı karakteri canlandırabilir.",
    ),

    WordItem(
      word: "GELİŞTİRİCİ",
      category: "Meslek",
      hint: "Yazılım ve uygulama üreten kişidir.",
      info:
          "Mobil uygulama geliştiricileri Flutter gibi teknolojiler kullanır.",
    ),

    WordItem(
      word: "ALGORİTMA",
      category: "Bilişim",
      hint: "Bir problemi çözmek için izlenen adımlar dizisidir.",
      info: "Programlamanın temel taşlarından biri algoritmadır.",
    ),

    WordItem(
      word: "MÜHENDİS",
      category: "Meslek",
      hint: "Teknik çözümler geliştiren uzman kişidir.",
      info: "Mühendisler birçok farklı alanda çalışabilir.",
    ),
  ];

  static const List<WordItem> hardWords = [
    WordItem(
      word: "KONSTANTİNOPOLİS",
      category: "Tarih",
      hint: "İstanbul'un eski adlarından biridir.",
      info:
          "Konstantinopolis yaklaşık 1600 yıl boyunca önemli bir başkent olmuştur.",
    ),

    WordItem(
      word: "ELEKTROMANYETİK",
      category: "Fizik",
      hint: "Elektrik ve manyetizma ile ilgilidir.",
      info: "Işık da elektromanyetik dalgalardan oluşur.",
    ),

    WordItem(
      word: "PARALELOGRAM",
      category: "Matematik",
      hint: "Karşılıklı kenarları paralel olan dörtgendir.",
      info: "Paralelogramın karşılıklı açıları birbirine eşittir.",
    ),

    WordItem(
      word: "ANAYASACILIK",
      category: "Hukuk",
      hint: "Devletin temel hukuk düzeniyle ilgilidir.",
      info: "Anayasacılık birey haklarını güvence altına almayı amaçlar.",
    ),

    WordItem(
      word: "JEOMORFOLOJİ",
      category: "Coğrafya",
      hint: "Yer şekillerini inceleyen bilim dalıdır.",
      info: "Dağlar, ovalar ve vadiler jeomorfolojinin konusudur.",
    ),

    WordItem(
      word: "NÖROPSİKOLOJİ",
      category: "Psikoloji",
      hint: "Beyin ile davranış ilişkisini inceler.",
      info: "Nöropsikoloji hem psikoloji hem de nörolojiden yararlanır.",
    ),

    WordItem(
      word: "ASTRONOMİ",
      category: "Uzay",
      hint: "Gezegenleri ve yıldızları inceleyen bilim dalıdır.",
      info: "Astronomi insanlığın en eski bilim dallarından biridir.",
    ),

    WordItem(
      word: "MİKROBİYOLOJİ",
      category: "Biyoloji",
      hint: "Mikroskobik canlıları inceler.",
      info: "Bakteriler ve virüsler mikrobiyolojinin çalışma alanındadır.",
    ),

    WordItem(
      word: "FOTOSENTEZ",
      category: "Biyoloji",
      hint: "Bitkilerin besin üretme olayıdır.",
      info: "Fotosentez sayesinde atmosferde oksijen oluşur.",
    ),

    WordItem(
      word: "TERMODİNAMİK",
      category: "Fizik",
      hint: "Isı ve enerji dönüşümlerini inceler.",
      info: "Motorların çalışma prensipleri termodinamik kurallarına dayanır.",
    ),
  ];
}
