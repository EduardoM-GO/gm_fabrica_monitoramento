enum TypeRawDataEnum {
  hit,
  door,
  telem;

  static TypeRawDataEnum fromMap(Map<String, dynamic> map) =>
      switch (map['t']) {
        "hit" => TypeRawDataEnum.hit,
        "door" => TypeRawDataEnum.door,
        "telem" => TypeRawDataEnum.telem,
        var value => throw Exception("Tipo de dado inválido: $value"),
      };
}
