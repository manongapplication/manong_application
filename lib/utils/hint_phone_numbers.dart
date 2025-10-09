String getExampleNumber(String countryCode) {
  switch (countryCode) {
    case 'PH':
      return '912 345 6789';
    case 'US':
      return '201 555 0123';
    case 'IN':
      return '91234 56789';
    default:
      return '';
  }
}