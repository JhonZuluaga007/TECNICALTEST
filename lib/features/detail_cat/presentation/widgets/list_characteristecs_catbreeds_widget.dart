import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/common_widgets/breed_characteristic_widget.dart';

class ListCharacteristicsCatbreeds extends StatelessWidget {
  final List<String> characteriticsNames;
  final List<int> characteriticsValue;
  final double? fontSize;
  final double? radius;

  /// Clase que representa un gato con sus características y valores correspondientes.
  ///
  /// Esta clase se utiliza para almacenar las características de un gato junto con sus valores correspondientes en un orden específico.
  ///
  /// Lista de nombres de las características del gato.
  ///
  /// Debes proporcionar los nombres de cada característica del gato en el mismo orden que sus valores correspondientes en [characteristicsValues].
  ///
  /// Lista de valores de las características del gato.
  ///
  /// Debes proporcionar los valores correspondientes a las características del gato en el mismo orden que sus nombres en [characteristicsNames].
  ///
  ///
  /// Ejemplo de uso
  ///
  /// ListCharacteristicsCatbreeds(
  ///
  ///   characteriticsNames: ["Color", "Edad", "Peso"],
  ///
  ///   characteriticsValue: ["Negro", 3, 4.5],
  ///
  /// );
  const ListCharacteristicsCatbreeds(
      {super.key,
      required this.characteriticsNames,
      required this.characteriticsValue,
      this.fontSize,
      this.radius});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        child: Column(
            children: List.generate(characteriticsNames.length, (index) {
      return Column(
        children: [
          BreedCharacteristicWidget(
              width: 500.w,
              height: 30,
              radius: radius ?? 10,
              fontSize: fontSize ?? 18,
              nameCharacteristic: characteriticsNames[index],
              value: characteriticsValue[index]),
          SizedBox(height: 8.h),
        ],
      );
    })));
  }
}
