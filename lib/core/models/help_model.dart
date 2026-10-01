/// Help center models — `GET /api/help` (contacts + FAQs).
library;

class HelpContact {
  const HelpContact({
    this.id,
    this.type,
    this.title,
    this.value,
    this.icon,
  });

  final int? id;
  final String? type;
  final String? title;
  final String? value;
  final String? icon;

  factory HelpContact.fromJson(dynamic json) {
    final j = json as Map<String, dynamic>;
    return HelpContact(
      id: (j['id'] as num?)?.toInt(),
      type: j['type'] as String?,
      title: j['title'] as String?,
      value: j['value'] as String?,
      icon: j['icon'] as String?,
    );
  }
}

class Faq {
  const Faq({this.id, this.question, this.answer});

  final int? id;
  final String? question;
  final String? answer;

  factory Faq.fromJson(dynamic json) {
    final j = json as Map<String, dynamic>;
    return Faq(
      id: (j['id'] as num?)?.toInt(),
      question: j['question'] as String?,
      answer: j['answer'] as String?,
    );
  }
}

class HelpData {
  const HelpData({this.contacts = const [], this.faqs = const []});

  final List<HelpContact> contacts;
  final List<Faq> faqs;

  factory HelpData.fromJson(dynamic json) {
    final j = json as Map<String, dynamic>;
    return HelpData(
      contacts:
          ((j['contacts'] as List?) ?? []).map(HelpContact.fromJson).toList(),
      faqs: ((j['faqs'] as List?) ?? []).map(Faq.fromJson).toList(),
    );
  }
}
