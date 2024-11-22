import 'dart:convert';

Welcome welcomeFromJson(String str) => Welcome.fromJson(json.decode(str));

class Welcome {
  Welcome({
    required this.cities,
  });

  List<City> cities;

  factory Welcome.fromJson(Map<String, dynamic> json) => Welcome(
        cities: List<City>.from(json["cities"].map((x) => City.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "cities": List<dynamic>.from(cities.map((x) => x.toJson())),
      };
}

class City {
  City({
    required this.id,
    required this.name,
  });

  int id;
  String name;

  factory City.fromJson(Map<String, dynamic> json) => City(
        id: json["id"],
        name: json["name"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
      };
}

List<City> cityList = [
  City(id: 1, name: "Анталия"),
  City(id: 2, name: "Истанбул"),
  City(id: 3, name: "Анкара"),
];

String getCityName(int? cityId, List<City> cities) {
  return cities.firstWhere((city) => city.id == cityId, orElse: () => City(id: 0, name: "Unknown")).name;
}
