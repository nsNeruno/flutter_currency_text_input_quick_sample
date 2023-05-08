extension FloatingUtils on num {

  int get decimalPlaces {
    int i = 0;
    num n = this;
    while (n % 1 != 0) {
      n *= 10;
      i++;
    }
    return i;
  }
}
