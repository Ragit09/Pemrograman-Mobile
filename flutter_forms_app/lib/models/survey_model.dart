class Survey {
  String respondentName;
  int age;
  String occupation;
  Map<String, String> radioAnswers;
  Map<String, List<String>> checkboxAnswers;
  String feedback;

  Survey({
    this.respondentName = '',
    this.age = 0,
    this.occupation = '',
    Map<String, String>? radioAnswers,
    Map<String, List<String>>? checkboxAnswers,
    this.feedback = '',
  })  : radioAnswers = Map<String, String>.from(radioAnswers ?? {}),
        checkboxAnswers = Map<String, List<String>>.from(checkboxAnswers ?? {});

  // Method untuk update radio answer dengan aman
  void updateRadioAnswer(String key, String value) {
    radioAnswers[key] = value;
  }

  // Method untuk update checkbox answer dengan aman
  void updateCheckboxAnswer(String key, List<String> values) {
    checkboxAnswers[key] = List<String>.from(values);
  }

  Map<String, dynamic> toJson() {
    return {
      'respondentName': respondentName,
      'age': age,
      'occupation': occupation,
      'radioAnswers': radioAnswers,
      'checkboxAnswers': checkboxAnswers,
      'feedback': feedback,
    };
  }

  factory Survey.fromJson(Map<String, dynamic> json) {
    return Survey(
      respondentName: json['respondentName']?.toString() ?? '',
      age: (json['age'] as int?) ?? 0,
      occupation: json['occupation']?.toString() ?? '',
      radioAnswers: Map<String, String>.from(json['radioAnswers'] ?? {}),
      checkboxAnswers: Map<String, List<String>>.from(json['checkboxAnswers'] ?? {}),
      feedback: json['feedback']?.toString() ?? '',
    );
  }
}