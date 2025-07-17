class Note {
  int? id; // Veritabanı ID'si
  String title; // Not başlığı
  String content; // Not içeriği
  String date; // Notun oluşturulma/güncellenme tarihi

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.date,
  });

  // Not objesini Map'e dönüştürme (veritabanına kaydetmek için)
  Map<String, dynamic> toMap() {
    return {'id': id, 'title': title, 'content': content, 'date': date};
  }

  // Map'ten Not objesi oluşturma (veritabanından okumak için)
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      date: map['date'],
    );
  }
}
