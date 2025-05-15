import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:tecnical_test_pragma/core/config/helpers/endpoints.dart';
import 'package:tecnical_test_pragma/features/landing_cats/data/models/catbreed_model.dart';

import '../../../../core/config/helpers/errors/invalid_data.dart';

class LandingCatsDataSource {
  Future<List<CatBreedModel>> getAllCats() async {
    var response = await http.get(Uri.parse(Endpoints.urlAllCats),
        headers: {"api-key": "bda53789-d59e-46cd-9bc4-2936630fde39"});
    try {
      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          List<CatBreedModel> allCatsResponse =
              catBreedModelFromMap(response.body);

          List<CatBreedModel> allCatsWithImage = [];
          for (var i = 0; i < allCatsResponse.length; i++) {
            allCatsWithImage.add(await getImageOfTheCat(
                allCatsResponse[i].referenceImageId, allCatsResponse[i]));
          }
          return allCatsWithImage;
        } else {
          return [];
        }
      }
      throw InvalidData(
          message: "Error al llamar el servicio",
          statusCode: response.statusCode);
    } catch (error) {
      throw InvalidData(
          message: "Este es el error del servicio: $error",
          statusCode: response.statusCode);
    }
  }

  Future<CatBreedModel> getImageOfTheCat(
      String referenceId, CatBreedModel catBreedModel) async {
    var response = await http.get(
        Uri.parse("${Endpoints.urlForGetImageCat}$referenceId"),
        headers: {"api-key": "bda53789-d59e-46cd-9bc4-2936630fde39"});
    if (response.statusCode == 200) {
      final mapInfo = json.decode(response.body);
      catBreedModel.urlImage = mapInfo["url"];
      return catBreedModel;
    } else {
      return catBreedModel;
    }
  }
}
