String currencySymbol(String cur) {
  switch (cur) {
    case "USD":
      return r"$";
    case "EUR":
      return "€";
    case "GBP":
      return "£";
    case "CAD":
      return "C";
    case "AED":
      return "د.إ";
    case "PKR":
      return "₨";
    default:
      return cur;
  }
}
