enum BMICategory {
  underweight,
  normal,
  overweight,
  obese,
}

class HealthCalculator {
  /// Tính BMI (Body Mass Index)
  /// BMI = weight (kg) / (height (m))^2
  static double calculateBMI(double weightKg, double heightCm) {
    if (heightCm <= 0 || weightKg <= 0) return 0;
    final heightM = heightCm / 100.0;
    return weightKg / (heightM * heightM);
  }

  /// Phân loại BMI theo WHO
  static BMICategory getBMICategory(double bmi) {
    if (bmi < 18.5) {
      return BMICategory.underweight;
    } else if (bmi < 25) {
      return BMICategory.normal;
    } else if (bmi < 30) {
      return BMICategory.overweight;
    } else {
      return BMICategory.obese;
    }
  }

  /// Lấy tên phân loại BMI bằng tiếng Việt
  static String getBMICategoryName(BMICategory category) {
    switch (category) {
      case BMICategory.underweight:
        return 'Thiếu cân';
      case BMICategory.normal:
        return 'Bình thường';
      case BMICategory.overweight:
        return 'Thừa cân';
      case BMICategory.obese:
        return 'Béo phì';
    }
  }

  /// Lấy màu sắc cho BMI category
  static int getBMICategoryColor(BMICategory category) {
    switch (category) {
      case BMICategory.underweight:
        return 0xFF2196F3; // Blue
      case BMICategory.normal:
        return 0xFF4CAF50; // Green
      case BMICategory.overweight:
        return 0xFFFF9800; // Orange
      case BMICategory.obese:
        return 0xFFF44336; // Red
    }
  }

  /// Kiểm tra BMI có bất thường không
  static bool isBMIAbnormal(double bmi) {
    return bmi < 18.5 || bmi >= 30;
  }

  /// Lấy gợi ý điều chỉnh dựa trên BMI
  static String getBMIAdvice(BMICategory category) {
    switch (category) {
      case BMICategory.underweight:
        return 'Bạn đang thiếu cân. Hãy tăng cường dinh dưỡng và tập luyện để tăng cân một cách lành mạnh.';
      case BMICategory.normal:
        return 'Chúc mừng! BMI của bạn ở mức bình thường. Hãy duy trì chế độ ăn uống và tập luyện hợp lý.';
      case BMICategory.overweight:
        return 'Bạn đang thừa cân. Hãy giảm cân bằng cách kết hợp chế độ ăn uống lành mạnh và tập luyện thường xuyên.';
      case BMICategory.obese:
        return 'Bạn đang ở mức béo phì. Hãy tham khảo ý kiến bác sĩ để có kế hoạch giảm cân an toàn và hiệu quả.';
    }
  }

  /// Tính lượng calo cần thiết mỗi ngày (BMR - Basal Metabolic Rate)
  /// Sử dụng công thức Mifflin-St Jeor
  static double calculateBMR({
    required double weightKg,
    required double heightCm,
    required int age,
    required bool isMale,
  }) {
    if (weightKg <= 0 || heightCm <= 0 || age <= 0) return 0;
    
    // Công thức Mifflin-St Jeor
    // BMR (nam) = 10 × weight(kg) + 6.25 × height(cm) - 5 × age(years) + 5
    // BMR (nữ) = 10 × weight(kg) + 6.25 × height(cm) - 5 × age(years) - 161
    final baseBMR = 10 * weightKg + 6.25 * heightCm - 5 * age;
    return isMale ? baseBMR + 5 : baseBMR - 161;
  }

  /// Tính TDEE (Total Daily Energy Expenditure) - Tổng năng lượng tiêu thụ mỗi ngày
  /// TDEE = BMR × Activity Factor
  static double calculateTDEE({
    required double bmr,
    required double activityFactor, // 1.2 (ít vận động) đến 1.9 (rất năng động)
  }) {
    return bmr * activityFactor;
  }
}

